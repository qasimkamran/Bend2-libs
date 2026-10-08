// Wire
// Native symbols and include guards are scoped to this local binding so it
// can coexist with the HTTP server's pinned bend-kit-wire implementation.
// ====
// Base's socket effects decode and encode UTF-8. These move octets as they
// are: one Char per byte (0..255) in, and each Char's low byte out.

#ifndef DIRECT_H1_WIRE_BYTES
#define DIRECT_H1_WIRE_BYTES

static Term direct_h1_wire_bytes(Env e, const char* p, u64 n) {
    Term s    = term_pak(CID(SNil), 0);
    u64  hole = 0;
    for (u64 i = 0; i < n; i += 1) {
        u64  l = heap_alloc(e, 1);
        Term t = term_ctr(CID(SCon), l);
        e.mem[l] = (uint8_t)p[i];
        if (hole == 0) {
            s = t;
        } else {
            e.mem[hole] = io_seal(e, t, CID(SCon));
        }
        hole = l + 1;
    }
    if (hole != 0) {
        e.mem[hole] = io_seal(e, term_pak(CID(SNil), 0), CID(SCon));
    }
    return s;
}

// A Char above 255 is not an octet; the send fails with EINVAL.
static char* direct_h1_wire_octets(Env e, Term s, u64* len, bool* bad) {
    u64   cap = 64;
    u64   n   = 0;
    char* buf = io_mem(malloc(cap));
    *bad = false;
    while (term_aux(s) == CID(SCon)) {
        Term fb[2];
        spare_free(e, cls_fit(2), ctr_take(e, s, 2, fb));
        if (n + 1 > cap) {
            cap *= 2;
            buf = io_mem(realloc(buf, cap));
        }
        *bad = *bad || (u64)fb[0] > 255;
        buf[n++] = (char)(fb[0] & 0xFF);
        s = fb[1];
    }
    *len = n;
    return buf;
}

// Bytes as bytes/bytes.bend packs them: byte i in bits 8*(i%4) of word i/4,
// 2^d words (the fewest that hold n), zero past n. Leans on the runtime's BUF
// block (blk_new, blk_loc, blk_read, blk_write); recheck on a Bend upgrade.
static Term direct_h1_wire_words(Env e, const char* p, u64 n) {
    u64  w    = (n + 3) / 4;
    u64  d    = 0;
    Term zero = 0;
    while ((1ull << d) < w) {
        d += 1;
    }
    Term a = blk_new(e, false, d, 0, 1, &zero);
    u64  l = blk_loc(e.mem, a);
    for (u64 k = 0; k < w; k += 1) {
        u32 x = 0;
        for (u64 j = 0; j < 4 && 4 * k + j < n; j += 1) {
            x |= (u32)(uint8_t)p[4 * k + j] << (8 * j);
        }
        blk_write(e.mem, false, l, (u32)k, x);
    }
    return io_tup(e, (Term)n, a);
}

// The first n bytes of a U32 BUF; n past its end fails with EINVAL.
static char* direct_h1_wire_words_octets(Env e, Term a, u64 n, u64* len, bool* bad) {
    u64* H = e.mem;
    *bad     = term_tag(a) != TAG_BUF || n > (4ull << blk_cls(a));
    *len     = *bad ? 0 : n;
    char* buf = io_mem(malloc(*len + 1));
    u64   l   = *bad ? 0 : blk_loc(H, a);
    for (u64 i = 0; i < *len; i += 1) {
        buf[i] = (char)(blk_read(H, false, l, (u32)(i / 4)) >> (8 * (i % 4)));
    }
    term_drop(e, a);
    return buf;
}

// A deadline in io_tick() nanoseconds, or 0 for none.
static u64 direct_h1_wire_deadline(u64 ms) {
    return ms != 0 ? io_tick() + ms * 1000000ull : 0;
}

static bool direct_h1_wire_late(u64 at) {
    return at != 0 && io_tick() >= at;
}

#endif

#if defined(CID(recv)) || defined(CID(recv.words))

// Not IO_READ: that would wait for readability before run, with no deadline.
// w->size holds the deadline until the read lands.
static Term direct_h1_wire_recv_go(Env e, IoWork* w, IoPack more, bool words) {
    int     fd = (int)w->hand;
    ssize_t n  = io_sys_end(w, recv(fd, w->data, (size_t)w->made, 0));
    if (w->code == EAGAIN) {
        if (!direct_h1_wire_late(w->size)) {
            return io_wait_on(w, fd, POLLIN, w->size, more);
        }
        w->code = ETIMEDOUT;
    }
    Term r = w->code ? io_fail(e, w->code, NULL)
        : io_done(e, words ? direct_h1_wire_words(e, w->data, (u64)n) : direct_h1_wire_bytes(e, w->data, (u64)n));
    free(w->data);
    return io_tup(e, io_hand(w->hand), r);
}

static void direct_h1_wire_recv_init(Term* f, IoWork* w) {
    w->hand = (intptr_t)io_hand_v(f[0]);
    w->made = f[1] < INT32_MAX ? (intptr_t)f[1] : INT32_MAX;
    w->data = io_mem(malloc((size_t)w->made + 1));
    w->size = direct_h1_wire_deadline((u64)f[2]);
}

#endif

#ifdef CID(recv)

static Term direct_h1_wire_recv_more(Env e, IoWork* w) {
    return direct_h1_wire_recv_go(e, w, direct_h1_wire_recv_more, false);
}

Term direct_h1_wire_recv_run(Env e, Term* f, IoWork* w) {
    direct_h1_wire_recv_init(f, w);
    return direct_h1_wire_recv_more(e, w);
}

static void __attribute__((constructor)) direct_h1_wire_recv_use(void) {
    io_eff(CID(recv), direct_h1_wire_recv_run, 0);
}

#endif

#ifdef CID(recv.words)

static Term direct_h1_wire_recv_words_more(Env e, IoWork* w) {
    return direct_h1_wire_recv_go(e, w, direct_h1_wire_recv_words_more, true);
}

Term direct_h1_wire_recv_words_run(Env e, Term* f, IoWork* w) {
    direct_h1_wire_recv_init(f, w);
    return direct_h1_wire_recv_words_more(e, w);
}

static void __attribute__((constructor)) direct_h1_wire_recv_words_use(void) {
    io_eff(CID(recv.words), direct_h1_wire_recv_words_run, 0);
}

#endif

#if defined(CID(send)) || defined(CID(send.words)) || defined(CID(send.timeout))

static Term direct_h1_wire_send_more(Env e, IoWork* w) {
    int fd = (int)w->hand;
    while (w->code == 0 && (u64)w->made < w->size) {
        if (direct_h1_wire_late((u64)(uintptr_t)w->text)) {
            w->code = ETIMEDOUT;
            break;
        }
        ssize_t n = send(fd, w->data + w->made, w->size - (u64)w->made, 0);
        if (n < 0 && errno == EAGAIN) {
            u64 at = (u64)(uintptr_t)w->text;
            if (direct_h1_wire_late(at)) {
                w->code = ETIMEDOUT;
                break;
            }
            return io_wait_on(w, fd, POLLOUT, at, direct_h1_wire_send_more);
        }
        w->made += io_sys_end(w, n);
    }
    Term r = w->code != 0 ? io_fail(e, w->code, NULL)
        : io_done(e, term_pak(CID(Unit), 0));
    free(w->data);
    w->text = NULL;
    return io_tup(e, io_hand(w->hand), r);
}

#endif

#ifdef CID(send)

Term direct_h1_wire_send_run(Env e, Term* f, IoWork* w) {
    bool bad;
    w->hand = (intptr_t)io_hand_v(f[0]);
    w->data = direct_h1_wire_octets(e, f[1], &w->size, &bad);
    w->made = 0;
    w->code = bad ? EINVAL : 0;
    w->text = NULL;
    return direct_h1_wire_send_more(e, w);
}

static void __attribute__((constructor)) direct_h1_wire_send_use(void) {
    io_eff(CID(send), direct_h1_wire_send_run, 0);
}

#endif

#ifdef CID(send.timeout)

Term direct_h1_wire_send_timeout_run(Env e, Term* f, IoWork* w) {
    bool bad;
    w->hand = (intptr_t)io_hand_v(f[0]);
    w->data = direct_h1_wire_octets(e, f[1], &w->size, &bad);
    w->made = 0;
    w->code = bad ? EINVAL : 0;
    w->text = (char*)(uintptr_t)direct_h1_wire_deadline((u64)f[2]);
    return direct_h1_wire_send_more(e, w);
}

static void __attribute__((constructor)) direct_h1_wire_send_timeout_use(void) {
    io_eff(CID(send.timeout), direct_h1_wire_send_timeout_run, 0);
}

#endif

#ifdef CID(send.words)

Term direct_h1_wire_send_words_run(Env e, Term* f, IoWork* w) {
    bool bad;
    w->hand = (intptr_t)io_hand_v(f[0]);
    w->data = direct_h1_wire_words_octets(e, f[2], (u64)f[1], &w->size, &bad);
    w->made = 0;
    w->code = bad ? EINVAL : 0;
    w->text = NULL;
    w->text = NULL;
    return direct_h1_wire_send_more(e, w);
}

static void __attribute__((constructor)) direct_h1_wire_send_words_use(void) {
    io_eff(CID(send.words), direct_h1_wire_send_words_run, 0);
}

#endif

#if defined(CID(connect)) || defined(CID(send_to)) || defined(CID(send_to.words))

// Accept only numeric addresses. The socket family and sockaddr length travel together.
static int direct_h1_wire_addr(const char* host, u32 port, struct sockaddr_storage* out, socklen_t* size) {
    if (port > 65535) {
        return -1;
    }
    struct in_addr v4;
    if (inet_pton(AF_INET, host, &v4) == 1) {
        struct sockaddr_in* a = (struct sockaddr_in*)out;
        memset(a, 0, sizeof(*a));
        a->sin_family = AF_INET;
        a->sin_port = htons((uint16_t)port);
        a->sin_addr = v4;
        *size = sizeof(*a);
        return AF_INET;
    }
    struct in6_addr v6;
    if (inet_pton(AF_INET6, host, &v6) == 1) {
        struct sockaddr_in6* a = (struct sockaddr_in6*)out;
        memset(a, 0, sizeof(*a));
        a->sin6_family = AF_INET6;
        a->sin6_port = htons((uint16_t)port);
        a->sin6_addr = v6;
        *size = sizeof(*a);
        return AF_INET6;
    }
    return -1;
}

#endif

#if defined(CID(recv_from)) || defined(CID(recv_from.words))

static Term direct_h1_wire_recv_from_go(Env e, IoWork* w, IoPack more, bool words) {
    struct sockaddr_storage at = { 0 };
    socklen_t alen = sizeof(at);
    char      host[INET6_ADDRSTRLEN];
    int       fd = (int)w->hand;
    ssize_t   n = io_sys_end(w, recvfrom(fd, w->data, (size_t)w->made, 0,
        (struct sockaddr*)&at, &alen));
    if (w->code == EAGAIN) {
        if (!direct_h1_wire_late(w->size)) {
            return io_wait_on(w, fd, POLLIN, w->size, more);
        }
        w->code = ETIMEDOUT;
    }
    const void* ip = at.ss_family == AF_INET6
        ? (const void*)&((struct sockaddr_in6*)&at)->sin6_addr
        : (const void*)&((struct sockaddr_in*)&at)->sin_addr;
    uint16_t port = at.ss_family == AF_INET6
        ? ((struct sockaddr_in6*)&at)->sin6_port
        : ((struct sockaddr_in*)&at)->sin_port;
    const char* text = w->code ? NULL : inet_ntop(at.ss_family, ip, host, sizeof(host));
    Term r = w->code || text == NULL ? io_fail(e, w->code ? w->code : EINVAL, NULL)
        : io_done(e, io_tup(e, io_str(e, text, strlen(text)),
            io_tup(e, ntohs(port), words
                ? direct_h1_wire_words(e, w->data, (u64)n) : direct_h1_wire_bytes(e, w->data, (u64)n))));
    free(w->data);
    return io_tup(e, io_hand(w->hand), r);
}

static void direct_h1_wire_recv_from_init(Term* f, IoWork* w) {
    w->hand = (intptr_t)io_hand_v(f[0]);
    w->made = f[1] < INT32_MAX ? (intptr_t)f[1] : INT32_MAX;
    w->data = io_mem(malloc((size_t)w->made + 1));
    w->size = direct_h1_wire_deadline((u64)f[2]);
}

#endif

#ifdef CID(recv_from)

static Term direct_h1_wire_recv_from_more(Env e, IoWork* w) {
    return direct_h1_wire_recv_from_go(e, w, direct_h1_wire_recv_from_more, false);
}

Term direct_h1_wire_recv_from_run(Env e, Term* f, IoWork* w) {
    direct_h1_wire_recv_from_init(f, w);
    return direct_h1_wire_recv_from_more(e, w);
}

static void __attribute__((constructor)) direct_h1_wire_recv_from_use(void) {
    io_eff(CID(recv_from), direct_h1_wire_recv_from_run, 0);
}

#endif

#ifdef CID(recv_from.words)

static Term direct_h1_wire_recv_from_words_more(Env e, IoWork* w) {
    return direct_h1_wire_recv_from_go(e, w, direct_h1_wire_recv_from_words_more, true);
}

Term direct_h1_wire_recv_from_words_run(Env e, Term* f, IoWork* w) {
    direct_h1_wire_recv_from_init(f, w);
    return direct_h1_wire_recv_from_words_more(e, w);
}

static void __attribute__((constructor)) direct_h1_wire_recv_from_words_use(void) {
    io_eff(CID(recv_from.words), direct_h1_wire_recv_from_words_run, 0);
}

#endif

#if defined(CID(send_to)) || defined(CID(send_to.words))

static Term direct_h1_wire_send_to_more(Env e, IoWork* w) {
    struct sockaddr_storage at;
    socklen_t size = 0;
    int     fd = (int)w->hand;
    ssize_t n = -1;
    errno     = EINVAL;
    if (w->code == 0 && direct_h1_wire_addr(w->text, (u32)w->made, &at, &size) >= 0) {
        n = sendto(fd, w->data, w->size, 0, (struct sockaddr*)&at, size);
    }
    io_sys_end(w, n);
    if (w->code == EAGAIN) {
        return io_wait_on(w, fd, POLLOUT, 0, direct_h1_wire_send_to_more);
    }
    Term r = w->code != 0 ? io_fail(e, w->code, NULL)
        : io_done(e, term_pak(CID(Unit), 0));
    free(w->text);
    free(w->data);
    return io_tup(e, io_hand(w->hand), r);
}

static void direct_h1_wire_send_to_init(Env e, Term* f, IoWork* w) {
    uint64_t hn = 0;
    w->hand = (intptr_t)io_hand_v(f[0]);
    w->text = io_cstr(e, f[1], &hn);
    w->made = (intptr_t)f[2];
    w->code = io_nul(w->text, hn) ? EINVAL : 0;
}

#endif

#ifdef CID(send_to)

Term direct_h1_wire_send_to_run(Env e, Term* f, IoWork* w) {
    bool bad;
    direct_h1_wire_send_to_init(e, f, w);
    w->data = direct_h1_wire_octets(e, f[3], &w->size, &bad);
    if (bad) w->code = EINVAL;
    return direct_h1_wire_send_to_more(e, w);
}

static void __attribute__((constructor)) direct_h1_wire_send_to_use(void) {
    io_eff(CID(send_to), direct_h1_wire_send_to_run, 0);
}

#endif

#ifdef CID(send_to.words)

Term direct_h1_wire_send_to_words_run(Env e, Term* f, IoWork* w) {
    bool bad;
    direct_h1_wire_send_to_init(e, f, w);
    w->data = direct_h1_wire_words_octets(e, f[4], (u64)f[3], &w->size, &bad);
    if (bad) w->code = EINVAL;
    return direct_h1_wire_send_to_more(e, w);
}

static void __attribute__((constructor)) direct_h1_wire_send_to_words_use(void) {
    io_eff(CID(send_to.words), direct_h1_wire_send_to_words_run, 0);
}

#endif

#ifdef CID(connect)

// Base's TCP.connect waits as long as the kernel does (~75 s); this one has a
// deadline. On each wake SO_ERROR reports a failure, and connect() again says
// EALREADY (still going) or EISCONN (done).
static Term direct_h1_wire_connect_end(Env e, IoWork* w, int err) {
    int fd = (int)w->hand;
    if (err != 0 && fd >= 0) {
        close(fd);
    }
    free(w->data);
    return err != 0 ? io_fail(e, (u32)err, NULL) : io_done(e, io_hand(fd));
}

static Term direct_h1_wire_connect_more(Env e, IoWork* w) {
    int       fd  = (int)w->hand;
    int       err = 0;
    socklen_t len = sizeof(err);
    if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &err, &len) != 0) {
        err = errno;
    }
    if (err == 0) {
        err = connect(fd, (struct sockaddr*)w->data, (socklen_t)w->made) == 0 ? 0 : errno;
    }
    if (err == 0 || err == EISCONN) {
        return direct_h1_wire_connect_end(e, w, 0);
    }
    if (err == EINPROGRESS || err == EALREADY) {
        if (!direct_h1_wire_late(w->size)) {
            return io_wait_on(w, fd, POLLOUT, w->size, direct_h1_wire_connect_more);
        }
        err = ETIMEDOUT;
    }
    return direct_h1_wire_connect_end(e, w, err);
}

Term direct_h1_connect_run(Env e, Term* f, IoWork* w) {
    struct sockaddr_storage at;
    socklen_t size = 0;
    u64 hn = 0;
    char* host = io_cstr(e, f[0], &hn);
    int family = io_nul(host, hn) ? -1 : direct_h1_wire_addr(host, (u32)f[1], &at, &size);
    free(host);
    w->data = NULL;
    w->hand = -1;
    if (family < 0) {
        return direct_h1_wire_connect_end(e, w, EINVAL);
    }
    w->data = io_mem(malloc(size));
    memcpy(w->data, &at, size);
    w->made = size;
    int fd = socket(family, SOCK_STREAM, 0);
    if (fd < 0) {
        return direct_h1_wire_connect_end(e, w, errno);
    }
    w->hand = fd;
    if (fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | O_NONBLOCK) < 0) {
        return direct_h1_wire_connect_end(e, w, errno);
    }
    w->size = direct_h1_wire_deadline((u64)f[2]);
    return direct_h1_wire_connect_more(e, w);
}

static void __attribute__((constructor)) direct_h1_connect_use(void) {
    io_eff(CID(connect), direct_h1_connect_run, 0);
}

#endif

// TLS
// ===
// OpenSSL 3, loaded at run time (bend links no extra libraries). The SSL
// object of a socket lives in a table keyed by its fd. Peer verification
// (chain + host name) is always on; TLS 1.2 is the floor.

#if defined(CID(tls.connect)) || defined(CID(tls.connect.alpn)) || defined(CID(tls.connect.cert)) \
    || defined(CID(tls.send)) || defined(CID(tls.recv)) || defined(CID(tls.close)) \
    || defined(CID(tls.send.words)) || defined(CID(tls.recv.words))
#ifndef DIRECT_H1_WIRE_TLS
#define DIRECT_H1_WIRE_TLS
#include <dlfcn.h>

typedef struct {
    int   state;
    void* ctx;
    void* (*ssl_new)(void*);
    int   (*set_fd)(void*, int);
    long  (*ctrl)(void*, int, long, void*);
    int   (*set1_host)(void*, const char*);
    int   (*connect)(void*);
    int   (*read)(void*, void*, int);
    int   (*write)(void*, const void*, int);
    int   (*get_error)(const void*, int);
    int   (*shutdown)(void*);
    void  (*ssl_free)(void*);
    long  (*verify_result)(const void*);
    const char* (*verify_text)(long);
    int   (*set_alpn_protos)(void*, const unsigned char*, unsigned int);
    void  (*get0_alpn_selected)(const void*, const unsigned char**, unsigned int*);
    int   (*use_certificate_chain_file)(void*, const char*);
    int   (*use_private_key_file)(void*, const char*, int);
    int   (*check_private_key)(const void*);
} DirectH1WireTls;

#define DIRECT_H1_WIRE_TLS_FDS 65536
static DirectH1WireTls direct_h1_wire_tls;
static void*   direct_h1_wire_tls_ssl[DIRECT_H1_WIRE_TLS_FDS];

static void* direct_h1_wire_tls_open(void) {
    const char* paths[] = { getenv("BEND_LIBSSL"),
        "/opt/homebrew/opt/openssl@3/lib/libssl.3.dylib",
        "/usr/local/opt/openssl@3/lib/libssl.3.dylib", "libssl.3.dylib", "libssl.so.3" };
    for (u64 i = 0; i < sizeof(paths) / sizeof(paths[0]); i += 1) {
        void* h = paths[i] != NULL ? dlopen(paths[i], RTLD_NOW | RTLD_LOCAL) : NULL;
        if (h != NULL) {
            return h;
        }
    }
    return NULL;
}

static bool direct_h1_wire_tls_load(void) {
    if (direct_h1_wire_tls.state != 0) {
        return direct_h1_wire_tls.state > 0;
    }
    direct_h1_wire_tls.state = -1;
    void* h = direct_h1_wire_tls_open();
    if (h == NULL) {
        return false;
    }
    void* (*method)(void)                 = dlsym(h, "TLS_client_method");
    void* (*ctx_new)(void*)               = dlsym(h, "SSL_CTX_new");
    int   (*paths)(void*)                 = dlsym(h, "SSL_CTX_set_default_verify_paths");
    void  (*verify)(void*, int, void*)    = dlsym(h, "SSL_CTX_set_verify");
    long  (*ctx_ctrl)(void*, int, long, void*) = dlsym(h, "SSL_CTX_ctrl");
    direct_h1_wire_tls.ssl_new       = dlsym(h, "SSL_new");
    direct_h1_wire_tls.set_fd        = dlsym(h, "SSL_set_fd");
    direct_h1_wire_tls.ctrl          = dlsym(h, "SSL_ctrl");
    direct_h1_wire_tls.set1_host     = dlsym(h, "SSL_set1_host");
    direct_h1_wire_tls.connect       = dlsym(h, "SSL_connect");
    direct_h1_wire_tls.read          = dlsym(h, "SSL_read");
    direct_h1_wire_tls.write         = dlsym(h, "SSL_write");
    direct_h1_wire_tls.get_error     = dlsym(h, "SSL_get_error");
    direct_h1_wire_tls.shutdown      = dlsym(h, "SSL_shutdown");
    direct_h1_wire_tls.ssl_free      = dlsym(h, "SSL_free");
    direct_h1_wire_tls.verify_result      = dlsym(h, "SSL_get_verify_result");
    direct_h1_wire_tls.verify_text        = dlsym(h, "X509_verify_cert_error_string");
    direct_h1_wire_tls.set_alpn_protos    = dlsym(h, "SSL_set_alpn_protos");
    direct_h1_wire_tls.get0_alpn_selected = dlsym(h, "SSL_get0_alpn_selected");
    direct_h1_wire_tls.use_certificate_chain_file = dlsym(h, "SSL_use_certificate_chain_file");
    direct_h1_wire_tls.use_private_key_file = dlsym(h, "SSL_use_PrivateKey_file");
    direct_h1_wire_tls.check_private_key = dlsym(h, "SSL_check_private_key");
    if (!method || !ctx_new || !paths || !verify || !ctx_ctrl
        || !direct_h1_wire_tls.ssl_new || !direct_h1_wire_tls.set_fd || !direct_h1_wire_tls.ctrl
        || !direct_h1_wire_tls.set1_host || !direct_h1_wire_tls.connect || !direct_h1_wire_tls.read
        || !direct_h1_wire_tls.write || !direct_h1_wire_tls.get_error || !direct_h1_wire_tls.shutdown
        || !direct_h1_wire_tls.ssl_free || !direct_h1_wire_tls.verify_result || !direct_h1_wire_tls.verify_text
        || !direct_h1_wire_tls.set_alpn_protos || !direct_h1_wire_tls.get0_alpn_selected
        || !direct_h1_wire_tls.use_certificate_chain_file || !direct_h1_wire_tls.use_private_key_file
        || !direct_h1_wire_tls.check_private_key) {
        return false;
    }
    void* ctx = ctx_new(method());
    if (ctx == NULL || paths(ctx) != 1) {
        return false;
    }
    verify(ctx, 1, NULL);              // SSL_VERIFY_PEER
    ctx_ctrl(ctx, 123, 0x0303, NULL);  // SSL_CTRL_SET_MIN_PROTO_VERSION, TLS 1.2
    // A bare EOF is an error. close_notify is the only clean close.
    direct_h1_wire_tls.ctx   = ctx;
    direct_h1_wire_tls.state = 1;
    return true;
}

static void* direct_h1_wire_tls_of(int fd) {
    return fd >= 0 && fd < DIRECT_H1_WIRE_TLS_FDS ? direct_h1_wire_tls_ssl[fd] : NULL;
}

static void direct_h1_wire_tls_drop(int fd) {
    void* ssl = direct_h1_wire_tls_of(fd);
    if (ssl != NULL) {
        direct_h1_wire_tls.ssl_free(ssl);
        direct_h1_wire_tls_ssl[fd] = NULL;
    }
}

#endif
#endif

#if defined(CID(tls.connect)) || defined(CID(tls.connect.alpn)) || defined(CID(tls.connect.cert))

static Term direct_h1_wire_tls_connect_end(Env e, IoWork* w, Term r) {
    free(w->text);
    return io_tup(e, io_hand(w->hand), r);
}

static Term direct_h1_wire_tls_connect_fail(Env e, IoWork* w, u32 code, const char* why) {
    direct_h1_wire_tls_drop((int)w->hand);
    return direct_h1_wire_tls_connect_end(e, w, io_fail(e, code, why));
}

static Term direct_h1_wire_tls_connect_more(Env e, IoWork* w) {
    int   fd  = (int)w->hand;
    void* ssl = direct_h1_wire_tls_of(fd);
    int   r   = direct_h1_wire_tls.connect(ssl);
    if (r == 1) {
        if (w->made != 0) {
            const unsigned char* ad;
            unsigned int         an;
            direct_h1_wire_tls.get0_alpn_selected(ssl, &ad, &an);
            return direct_h1_wire_tls_connect_end(e, w, io_done(e, direct_h1_wire_bytes(e, (const char*)ad, an)));
        }
        return direct_h1_wire_tls_connect_end(e, w, io_done(e, term_pak(CID(Unit), 0)));
    }
    int err = direct_h1_wire_tls.get_error(ssl, r);
    if (err == 2 || err == 3) {  // SSL_ERROR_WANT_READ, SSL_ERROR_WANT_WRITE
        if (!direct_h1_wire_late(w->size)) {
            return io_wait_on(w, fd, err == 2 ? POLLIN : POLLOUT, w->size, direct_h1_wire_tls_connect_more);
        }
        return direct_h1_wire_tls_connect_fail(e, w, ETIMEDOUT, NULL);
    }
    long v = direct_h1_wire_tls.verify_result(ssl);
    return direct_h1_wire_tls_connect_fail(e, w, EPROTO, v != 0 ? direct_h1_wire_tls.verify_text(v) : "TLS handshake failed");
}

static Term direct_h1_wire_tls_connect_start(Env e, IoWork* w, int fd, void* ssl) {
    direct_h1_wire_tls_ssl[fd] = ssl;
    if (direct_h1_wire_tls.set_fd(ssl, fd) != 1 || direct_h1_wire_tls.ctrl(ssl, 55, 0, w->text) != 1
        || direct_h1_wire_tls.set1_host(ssl, w->text) != 1) {
        return direct_h1_wire_tls_connect_fail(e, w, EPROTO, "TLS setup failed");
    }
    return direct_h1_wire_tls_connect_more(e, w);
}

#endif

#ifdef CID(tls.connect)

Term direct_h1_tls_connect_run(Env e, Term* f, IoWork* w) {
    uint64_t hn = 0;
    w->hand = (intptr_t)io_hand_v(f[0]);
    w->text = io_cstr(e, f[1], &hn);
    w->size = direct_h1_wire_deadline((u64)f[2]);
    w->made = 0;
    int fd  = (int)w->hand;
    if (!direct_h1_wire_tls_load()) {
        return direct_h1_wire_tls_connect_end(e, w, io_fail(e, ENOENT, "TLS needs OpenSSL 3 (libssl.3); set BEND_LIBSSL to its path"));
    }
    if (fd < 0 || fd >= DIRECT_H1_WIRE_TLS_FDS || io_nul(w->text, hn)) {
        return direct_h1_wire_tls_connect_end(e, w, io_fail(e, EINVAL, NULL));
    }
    void* ssl = direct_h1_wire_tls.ssl_new(direct_h1_wire_tls.ctx);
    if (ssl == NULL) {
        return direct_h1_wire_tls_connect_end(e, w, io_fail(e, ENOMEM, NULL));
    }
    return direct_h1_wire_tls_connect_start(e, w, fd, ssl);
}

static void __attribute__((constructor)) direct_h1_tls_connect_use(void) {
    io_eff(CID(tls.connect), direct_h1_tls_connect_run, 0);
}

#endif

#ifdef CID(tls.connect.alpn)

// Comma-separated protocol names to the ALPN wire form (RFC 7301).
static bool direct_h1_wire_alpn_pack(const char* list, u64 len, unsigned char* buf, unsigned int* n, unsigned int max) {
    u64 start = 0;
    *n        = 0;
    for (u64 i = 0; i <= len; i += 1) {
        if (i < len && list[i] != ',') {
            continue;
        }
        u64 plen = i - start;
        if (plen == 0 || plen > 255 || *n + 1 + plen > max) {
            return false;
        }
        buf[(*n)++] = (unsigned char)plen;
        memcpy(buf + *n, list + start, plen);
        *n += (unsigned int)plen;
        start = i + 1;
    }
    return true;
}

Term direct_h1_tls_connect_alpn_run(Env e, Term* f, IoWork* w) {
    uint64_t hn = 0;
    uint64_t pn = 0;
    w->hand = (intptr_t)io_hand_v(f[0]);
    w->text = io_cstr(e, f[1], &hn);
    w->size = direct_h1_wire_deadline((u64)f[2]);
    w->made = 1;
    char*         plist = io_cstr(e, f[3], &pn);
    unsigned char abuf[256];
    unsigned int  alen;
    int           fd = (int)w->hand;
    bool bad = fd < 0 || fd >= DIRECT_H1_WIRE_TLS_FDS || io_nul(w->text, hn) || io_nul(plist, pn)
        || !direct_h1_wire_alpn_pack(plist, pn, abuf, &alen, sizeof(abuf));
    free(plist);
    if (!direct_h1_wire_tls_load()) {
        return direct_h1_wire_tls_connect_end(e, w, io_fail(e, ENOENT, "TLS needs OpenSSL 3 (libssl.3); set BEND_LIBSSL to its path"));
    }
    if (bad) {
        return direct_h1_wire_tls_connect_end(e, w, io_fail(e, EINVAL, NULL));
    }
    void* ssl = direct_h1_wire_tls.ssl_new(direct_h1_wire_tls.ctx);
    if (ssl == NULL) {
        return direct_h1_wire_tls_connect_end(e, w, io_fail(e, ENOMEM, NULL));
    }
    if (direct_h1_wire_tls.set_alpn_protos(ssl, abuf, alen) != 0) {
        direct_h1_wire_tls.ssl_free(ssl);
        return direct_h1_wire_tls_connect_end(e, w, io_fail(e, EPROTO, "ALPN setup failed"));
    }
    return direct_h1_wire_tls_connect_start(e, w, fd, ssl);
}

static void __attribute__((constructor)) direct_h1_tls_connect_alpn_use(void) {
    io_eff(CID(tls.connect.alpn), direct_h1_tls_connect_alpn_run, 0);
}

#endif

#ifdef CID(tls.connect.cert)

Term direct_h1_tls_connect_cert_run(Env e, Term* f, IoWork* w) {
    uint64_t hn = 0, cn = 0, kn = 0;
    w->hand = (intptr_t)io_hand_v(f[0]);
    w->text = io_cstr(e, f[1], &hn);
    w->size = direct_h1_wire_deadline((u64)f[2]);
    w->made = 0;
    char* cert = io_cstr(e, f[3], &cn);
    char* key = io_cstr(e, f[4], &kn);
    int fd = (int)w->hand;
    bool bad = fd < 0 || fd >= DIRECT_H1_WIRE_TLS_FDS || io_nul(w->text, hn)
        || io_nul(cert, cn) || io_nul(key, kn) || cn == 0 || kn == 0;
    bool loaded = direct_h1_wire_tls_load();
    if (!loaded || bad) {
        free(cert);
        free(key);
        return direct_h1_wire_tls_connect_end(e, w, !loaded
            ? io_fail(e, ENOENT, "TLS needs OpenSSL 3 (libssl.3); set BEND_LIBSSL to its path")
            : io_fail(e, EINVAL, "Invalid TLS client certificate or key path"));
    }
    void* ssl = direct_h1_wire_tls.ssl_new(direct_h1_wire_tls.ctx);
    if (ssl == NULL) {
        free(cert);
        free(key);
        return direct_h1_wire_tls_connect_end(e, w, io_fail(e, ENOMEM, NULL));
    }
    const char* why = NULL;
    if (direct_h1_wire_tls.use_certificate_chain_file(ssl, cert) != 1) {
        why = "TLS client certificate load failed";
    } else if (direct_h1_wire_tls.use_private_key_file(ssl, key, 1) != 1) {
        why = "TLS client key load failed";
    } else if (direct_h1_wire_tls.check_private_key(ssl) != 1) {
        why = "TLS client key does not match certificate";
    }
    free(cert);
    free(key);
    if (why != NULL) {
        direct_h1_wire_tls.ssl_free(ssl);
        return direct_h1_wire_tls_connect_end(e, w, io_fail(e, EINVAL, why));
    }
    return direct_h1_wire_tls_connect_start(e, w, fd, ssl);
}

static void __attribute__((constructor)) direct_h1_tls_connect_cert_use(void) {
    io_eff(CID(tls.connect.cert), direct_h1_tls_connect_cert_run, 0);
}

#endif

#if defined(CID(tls.send)) || defined(CID(tls.send.words)) || defined(CID(tls.send.timeout))

// SSL_write is retried with the same buffer, as OpenSSL requires.
static Term direct_h1_wire_tls_send_more(Env e, IoWork* w) {
    int   fd  = (int)w->hand;
    void* ssl = direct_h1_wire_tls_of(fd);
    while (w->code == 0 && (u64)w->made < w->size) {
        if (direct_h1_wire_late((u64)(uintptr_t)w->text)) {
            w->code = ETIMEDOUT;
            break;
        }
        if (ssl == NULL) {
            w->code = EBADF;
            break;
        }
        u64 left = w->size - (u64)w->made;
        int n    = direct_h1_wire_tls.write(ssl, w->data + w->made, left > INT32_MAX ? INT32_MAX : (int)left);
        if (n > 0) {
            w->made += n;
            continue;
        }
        int err = direct_h1_wire_tls.get_error(ssl, n);
        if (err == 2 || err == 3) {
            u64 at = (u64)(uintptr_t)w->text;
            if (direct_h1_wire_late(at)) {
                w->code = ETIMEDOUT;
                break;
            }
            return io_wait_on(w, fd, err == 2 ? POLLIN : POLLOUT, at, direct_h1_wire_tls_send_more);
        }
        w->code = EPIPE;
    }
    Term r = w->code != 0 ? io_fail(e, w->code, NULL)
        : io_done(e, term_pak(CID(Unit), 0));
    free(w->data);
    w->text = NULL;
    return io_tup(e, io_hand(w->hand), r);
}

#endif

#ifdef CID(tls.send)

Term direct_h1_tls_send_run(Env e, Term* f, IoWork* w) {
    bool bad;
    w->hand = (intptr_t)io_hand_v(f[0]);
    w->data = direct_h1_wire_octets(e, f[1], &w->size, &bad);
    w->made = 0;
    w->code = bad ? EINVAL : 0;
    w->text = NULL;
    return direct_h1_wire_tls_send_more(e, w);
}

static void __attribute__((constructor)) direct_h1_tls_send_use(void) {
    io_eff(CID(tls.send), direct_h1_tls_send_run, 0);
}

#endif

#ifdef CID(tls.send.timeout)

Term direct_h1_tls_send_timeout_run(Env e, Term* f, IoWork* w) {
    bool bad;
    w->hand = (intptr_t)io_hand_v(f[0]);
    w->data = direct_h1_wire_octets(e, f[1], &w->size, &bad);
    w->made = 0;
    w->code = bad ? EINVAL : 0;
    w->text = (char*)(uintptr_t)direct_h1_wire_deadline((u64)f[2]);
    return direct_h1_wire_tls_send_more(e, w);
}

static void __attribute__((constructor)) direct_h1_tls_send_timeout_use(void) {
    io_eff(CID(tls.send.timeout), direct_h1_tls_send_timeout_run, 0);
}

#endif

#ifdef CID(tls.send.words)

Term direct_h1_tls_send_words_run(Env e, Term* f, IoWork* w) {
    bool bad;
    w->hand = (intptr_t)io_hand_v(f[0]);
    w->data = direct_h1_wire_words_octets(e, f[2], (u64)f[1], &w->size, &bad);
    w->made = 0;
    w->code = bad ? EINVAL : 0;
    w->text = NULL;
    w->text = NULL;
    return direct_h1_wire_tls_send_more(e, w);
}

static void __attribute__((constructor)) direct_h1_tls_send_words_use(void) {
    io_eff(CID(tls.send.words), direct_h1_tls_send_words_run, 0);
}

#endif

#if defined(CID(tls.recv)) || defined(CID(tls.recv.words))

// Empty means close_notify. A bare EOF is a read error, not a clean close.
static Term direct_h1_wire_tls_recv_go(Env e, IoWork* w, IoPack more, bool words) {
    int   fd  = (int)w->hand;
    void* ssl = direct_h1_wire_tls_of(fd);
    int   n   = ssl != NULL ? direct_h1_wire_tls.read(ssl, w->data, (int)w->made) : -1;
    Term  r;
    if (n > 0) {
        r = io_done(e, words ? direct_h1_wire_words(e, w->data, (u64)n) : direct_h1_wire_bytes(e, w->data, (u64)n));
    } else {
        int err = ssl != NULL ? direct_h1_wire_tls.get_error(ssl, n) : 1;
        if (err == 2 || err == 3) {
            if (!direct_h1_wire_late(w->size)) {
                return io_wait_on(w, fd, err == 2 ? POLLIN : POLLOUT, w->size, more);
            }
            err = -1;
        }
        r = err == 6 ? io_done(e, words ? direct_h1_wire_words(e, w->data, 0) : term_pak(CID(SNil), 0))  // SSL_ERROR_ZERO_RETURN
            : err == -1 ? io_fail(e, ETIMEDOUT, NULL)
            : io_fail(e, ssl != NULL ? EIO : EBADF, ssl != NULL ? "TLS read failed" : NULL);
    }
    free(w->data);
    return io_tup(e, io_hand(w->hand), r);
}

static void direct_h1_wire_tls_recv_init(Term* f, IoWork* w) {
    w->hand = (intptr_t)io_hand_v(f[0]);
    w->made = f[1] < INT32_MAX ? (intptr_t)f[1] : INT32_MAX;
    w->data = io_mem(malloc((size_t)w->made + 1));
    w->size = direct_h1_wire_deadline((u64)f[2]);
}

#endif

#ifdef CID(tls.recv)

static Term direct_h1_wire_tls_recv_more(Env e, IoWork* w) {
    return direct_h1_wire_tls_recv_go(e, w, direct_h1_wire_tls_recv_more, false);
}

Term direct_h1_tls_recv_run(Env e, Term* f, IoWork* w) {
    direct_h1_wire_tls_recv_init(f, w);
    return direct_h1_wire_tls_recv_more(e, w);
}

static void __attribute__((constructor)) direct_h1_tls_recv_use(void) {
    io_eff(CID(tls.recv), direct_h1_tls_recv_run, 0);
}

#endif

#ifdef CID(tls.recv.words)

static Term direct_h1_wire_tls_recv_words_more(Env e, IoWork* w) {
    return direct_h1_wire_tls_recv_go(e, w, direct_h1_wire_tls_recv_words_more, true);
}

Term direct_h1_tls_recv_words_run(Env e, Term* f, IoWork* w) {
    direct_h1_wire_tls_recv_init(f, w);
    return direct_h1_wire_tls_recv_words_more(e, w);
}

static void __attribute__((constructor)) direct_h1_tls_recv_words_use(void) {
    io_eff(CID(tls.recv.words), direct_h1_tls_recv_words_run, 0);
}

#endif

#ifdef CID(tls.close)

// ponytail: one non-blocking close_notify attempt; no wait for the peer's
Term direct_h1_tls_close_run(Env e, Term* f, IoWork* w) {
    int   fd  = (int)io_hand_v(f[0]);
    void* ssl = direct_h1_wire_tls_of(fd);
    if (ssl != NULL) {
        direct_h1_wire_tls.shutdown(ssl);
        direct_h1_wire_tls_drop(fd);
    }
    close(fd);
    return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) direct_h1_tls_close_use(void) {
    io_eff(CID(tls.close), direct_h1_tls_close_run, 0);
}

#endif
