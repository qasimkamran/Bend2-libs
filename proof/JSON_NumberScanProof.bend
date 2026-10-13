import Base
import ../libs/JSON.bend as J

# Scanner boundaries are separate from number grammar validation: signs,
# decimal points and exponent markers are collected, then checked by the parser.
def all_number_characters() ->
    {J.scan_number("-+.eE0123456789!tail", "") ==
        J.StringScan{"-+.eE0123456789", "!tail"} : J.StringScan}:
    {==}

def empty_input_keeps_reversed_accumulator() ->
    {J.scan_number("", "321") == J.StringScan{"123", ""} : J.StringScan}:
    {==}

def stops_at_first_delimiter() ->
    {J.scan_number("23,45", "1") == J.StringScan{"123", ",45"} : J.StringScan}:
    {==}

def stops_before_whitespace() ->
    {J.scan_number("1.5e+2 \n3", "") == J.StringScan{"1.5e+2", " \n3"} : J.StringScan}:
    {==}

def leading_non_number_is_untouched() ->
    {J.scan_number("x12", "") == J.StringScan{"", "x12"} : J.StringScan}:
    {==}

def unicode_digit_is_not_ascii_digit() ->
    {J.scan_number("\u{661}2", "") == J.StringScan{"", "\u{661}2"} : J.StringScan}:
    {==}

def digit_range_boundaries() ->
    {J.scan_number("09:12", "") == J.StringScan{"09", ":12"} : J.StringScan}:
    {==}

def slash_is_not_a_digit() ->
    {J.scan_number("/12", "") == J.StringScan{"", "/12"} : J.StringScan}:
    {==}
