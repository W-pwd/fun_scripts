Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
# CONFIGURATION
# ============================================================

$createdNew = $false

$mutex = New-Object System.Threading.Mutex($false,"THE_WATCHER",[ref]$createdNew)

if (-not $createdNew) {
    Write-Host "THE_WATCHER is already running."
[System.Windows.Forms.MessageBox]::Show(('The Watcher is already Running {0}{1}' -f '',[Environment]::NewLine,''))
    exit
}
[System.Windows.Forms.MessageBox]::Show(('The Watcher is STARTING {0}{1}' -f '',[Environment]::NewLine,''))
# ============================================================
# CONFIGURATION
# ============================================================

$folder = $PSScriptRoot
$alertImage = Join-Path $folder "alert.jpg"

# ============================================================
# CHECK ALERT IMAGE
# ============================================================

if (-not (Test-Path -LiteralPath $alertImage)) {
    Write-Host "ERROR: alert.jpg was not found:" -ForegroundColor Red
    Write-Host $alertImage -ForegroundColor Red
    exit 1
}

# ============================================================
# FILESYSTEM WATCHER
# ============================================================

$watcher = New-Object System.IO.FileSystemWatcher

$watcher.Path = $folder
$watcher.Filter = "*.*"
$watcher.IncludeSubdirectories = $false

# Watch:
# - FileName   = create/rename
# - LastWrite  = file modified
# - Size       = file size changed
$watcher.NotifyFilter =
    [System.IO.NotifyFilters]::FileName -bor
    [System.IO.NotifyFilters]::LastWrite -bor
    [System.IO.NotifyFilters]::Size

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "FILE WATCHER IS RUNNING" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Watching : $folder"
Write-Host "Alert    : $alertImage"
Write-Host ""
Write-Host "Rules:"
Write-Host "  - Filename contains ADD"
Write-Host "  - Filename is longer than 35 characters"
Write-Host ""
Write-Host "Watching for:"
Write-Host "  - New files"
Write-Host "  - Renamed files"
Write-Host "  - Moved files"
Write-Host "  - Modified files"
Write-Host ""
Write-Host "Press Ctrl+C to stop."
Write-Host "========================================"
Write-Host ""

# ============================================================
# EVENT TYPES
# ============================================================

$changeTypes =
    [System.IO.WatcherChangeTypes]::Created -bor
    [System.IO.WatcherChangeTypes]::Renamed -bor
    [System.IO.WatcherChangeTypes]::Changed

# ============================================================
# MAIN LOOP
# ============================================================

try {

    while ($true) {

        # Wait for an event.
        #
        # 1000 = 1 second timeout.
        #
        # This is NOT polling the folder.
        # Windows still waits for the filesystem event.
        # The timeout simply lets Ctrl+C terminate cleanly.

        $result = $watcher.WaitForChanged(
            $changeTypes,
            1000
        )

        if ($result.TimedOut) {
            continue
        }

        $fileName = $result.Name

        # Ignore the alert image itself
        if ($fileName -eq "alert.jpg") {
            continue
        }

        Write-Host ""
        Write-Host "FILE DETECTED: $fileName" -ForegroundColor Cyan
        Write-Host "Change type: $($result.ChangeType)" -ForegroundColor DarkCyan

        # ====================================================
        # GET FILENAME WITHOUT EXTENSION
        # ====================================================

        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)

        # ====================================================
        # CHECK RULES
        # ====================================================

        $containsADD = $baseName -match "ADD|Product|EXCEPTION|Issue|prepare|return" # $baseName -match "ADD"
        $tooLong = $baseName.Length -gt 30

        Write-Host "Filename length: $($baseName.Length)"

        if (-not ($containsADD -or $tooLong)) {

            Write-Host "No alert required." -ForegroundColor DarkGray
            continue
        }

        # ====================================================
        # DETERMINE REASON
        # ====================================================

        if ($containsADD -and $tooLong) {
            $reason = "Filename contains ADD and is longer than 35 characters"
        }
        elseif ($containsADD) {
            $reason = "Filename contains ADD"
        }
        else {
            $reason = "Filename is longer than 35 characters"
        }

        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "!!! FILE ALERT !!!" -ForegroundColor Red
        Write-Host "File:   $fileName"
        Write-Host "Reason: $reason"
        Write-Host "========================================" -ForegroundColor Red

        # ====================================================
        # SHOW ALERT
        # ====================================================

        try {

            $form = New-Object System.Windows.Forms.Form

            $form.Text = "FILE ALERT"
            $form.StartPosition = "CenterScreen"
            $form.FormBorderStyle =
                [System.Windows.Forms.FormBorderStyle]::None

            $form.TopMost = $true
            $form.ShowInTaskbar = $true
            $form.KeyPreview = $true
            $form.AutoSize = $true
            $form.AutoSizeMode =
                [System.Windows.Forms.AutoSizeMode]::GrowOnly

	    # Fullscreen
$form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized

            $image = [System.Drawing.Image]::FromFile($alertImage)

            $pictureBox = New-Object System.Windows.Forms.PictureBox

            $pictureBox.Image = $image
            $pictureBox.Dock = [System.Windows.Forms.DockStyle]::Fill

            # Make the image fill the screen
            $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom

            $form.Controls.Add($pictureBox)

            # Click image to close
            $pictureBox.Add_Click({
                $form.Close()
            })

            # ESC to close
            $form.Add_KeyDown({
                if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
                    $form.Close()
                }
            })

            # Show on top
            $form.ShowDialog() | Out-Null

            $image.Dispose()
            $pictureBox.Dispose()
            $form.Dispose()

        }
        catch {

            Write-Host ""
            Write-Host "ERROR SHOWING ALERT:" -ForegroundColor Red
            Write-Host $_.Exception.ToString() -ForegroundColor Red
        }
    }

}
finally {

    Write-Host ""
    Write-Host "Stopping watcher..." -ForegroundColor Yellow
    
if ($mutex) {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()

    Write-Host "Watcher stopped." -ForegroundColor Yellow
}
