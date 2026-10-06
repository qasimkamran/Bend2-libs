param(
    [ValidateSet("core", "wrapper", "constructors", "identity", "trace", "key-trace", "tag-compare", "tag-reject", "encrypt", "tamper", "vectors", "interop", "laws")]
    [string]$Checkpoint = "core"
)

$ErrorActionPreference = "Stop"

$targets = @{
    core        = "libs/AES256GCMCore.bend"
    wrapper     = "libs/AES256GCM.bend"
    constructors = "proof/AES_ConstructorProof.bend"
    identity    = "proof/AES_IdentityProof.bend"
    trace       = "proof/AES_TraceProof.bend"
    "key-trace" = "proof/AES_NistKeyScheduleProof.bend"
    "tag-compare" = "proof/AES_TagCompareProof.bend"
    "tag-reject"  = "proof/AES_TagRejectProof.bend"
    encrypt     = "proof/AES_EncryptProof.bend"
    tamper      = "proof/AES_TamperProof.bend"
    laws        = "PROOF.bend"
}

$aesWorkspace = Split-Path -Parent $PSScriptRoot
$aesStarted = Get-Date
Push-Location -LiteralPath $aesWorkspace
try {
    if ($Checkpoint -eq "vectors") {
        $aesExecutable = Join-Path ([IO.Path]::GetTempPath()) ("bend-aes-vectors-" + [Guid]::NewGuid().ToString("N") + ".exe")
        try {
            Write-Host "AES checkpoint: vectors (native NIST tests)"
            & bend usage/AES_NistTest.bend -o $aesExecutable
            if ($LASTEXITCODE -ne 0) {
                throw "AES vector test build failed with exit code $LASTEXITCODE"
            }
            $aesResult = & $aesExecutable --gpu off
            if ($LASTEXITCODE -ne 0 -or (($aesResult -join "`n").Trim() -ne "True{}")) {
                throw "AES vector tests failed: $aesResult"
            }
            Write-Host $aesResult
        } finally {
            if (Test-Path -LiteralPath $aesExecutable) {
                Remove-Item -LiteralPath $aesExecutable -Force
            }
        }
    } elseif ($Checkpoint -eq "interop") {
        $aesModule = Join-Path ([IO.Path]::GetTempPath()) ("bend-aes-interop-" + [Guid]::NewGuid().ToString("N") + ".mjs")
        try {
            Write-Host "AES checkpoint: interop (104 cases against Node/OpenSSL)"
            & bend libs/AES256GCM.bend -o $aesModule
            if ($LASTEXITCODE -ne 0) {
                throw "AES JavaScript build failed with exit code $LASTEXITCODE"
            }
            & node usage/AES_InteropTest.mjs $aesModule
            if ($LASTEXITCODE -ne 0) {
                throw "AES interoperability tests failed with exit code $LASTEXITCODE"
            }
        } finally {
            if (Test-Path -LiteralPath $aesModule) {
                Remove-Item -LiteralPath $aesModule -Force
            }
        }
    } else {
        $target = $targets[$Checkpoint]
        Write-Host "AES checkpoint: $Checkpoint ($target --verdict)"
        & bend $target --verdict
        if ($LASTEXITCODE -ne 0) {
            throw "AES checkpoint '$Checkpoint' failed with exit code $LASTEXITCODE"
        }
    }
    $aesElapsed = ((Get-Date) - $aesStarted).TotalSeconds
    Write-Host ("AES checkpoint passed: {0} ({1:N1}s)" -f $Checkpoint, $aesElapsed)
} finally {
    Pop-Location
}
