#Control your Spotify account from wherever

$ClientID = #Your Spotify Client ID goes here
$ClientSecret = #Your Spotify Client Secret goes here

$RefreshToken = #Your Spotify Refresh Token goes her

#Functions to aquire tokens

function GetToken {

    #Get an accesstoken if you just have the Client ID and Secret
    #Not currently in use

    $ClientIDAndSecret = $ClientID + ":" + $ClientSecret
    $ClientIdAndSecret = [System.Text.Encoding]::UTF8.GetBytes($ClientIdAndSecret)

    $Base64 = [System.Convert]::ToBase64String($ClientIDAndSecret)

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Basic $Base64")

    $Data = "grant_type=client_credentials"

    $Token = Invoke-RestMethod -Method Post -Uri "https://accounts.spotify.com/api/token" -Headers $Headers -Body $Data

}

function GetAccessToken {

    #Get an accessToken if you have a refreshtoken

    $RefreshToken = $RefreshToken

    $ClientIDAndSecret = $ClientID + ":" + $ClientSecret
    $ClientIdAndSecret = [System.Text.Encoding]::UTF8.GetBytes($ClientIdAndSecret)

    $Base64 = [System.Convert]::ToBase64String($ClientIDAndSecret)

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Basic $Base64")

    $Data = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $Data.Add("grant_type", "refresh_token")
    $Data.Add("refresh_token", "$RefreshToken")

    $Token = Invoke-RestMethod -Method Post -Uri "https://accounts.spotify.com/api/token" -Headers $Headers -Body $Data
    $Token

}

#Functions for the UI

Function PromptOptions {

    Write-Host "Remote control your Spotify playback, wherever it's currently playing" 
    Write-Host ""

    Write-Host "Input " -NoNewline
    Write-Host "Pause " -NoNewline -ForegroundColor Red
    Write-Host "to pause"

    Write-Host "Input " -NoNewline
    Write-Host "Play " -NoNewline -ForegroundColor Red
    Write-Host "to play"

    Write-Host "Input " -NoNewline
    Write-Host "Volume (0-100) " -NoNewline -ForegroundColor Red
    Write-Host "to adjust playback volume"

    Write-Host "Input " -NoNewline
    Write-Host "Skip Next / Skip Prev " -NoNewline -ForegroundColor Red
    Write-Host "to skip a song or go to the previous one"

    Write-Host "Input " -NoNewline
    Write-Host "Track " -NoNewline -ForegroundColor Red
    Write-Host "To see whats currently playing"

    Write-Host ""

}

Function PromptChoice {

    $Choice = $Null
    $Choice = Read-Host "Please input command"
    $Choice

}

#Functions to control playback

Function Pause {

    $Token = GetAccessToken

    $TokenHeaders = $Null
    $TokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $TokenHeaders.Add("Authorization", "Bearer $($Token.access_token)")

    Invoke-RestMethod -Method PUT -Headers $TokenHeaders -uri "https://api.spotify.com/v1/me/player/pause"

}

Function Resume {

    $Token = GetAccessToken

    $TokenHeaders = $Null
    $TokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $TokenHeaders.Add("Authorization", "Bearer $($Token.access_token)")

    Invoke-RestMethod -Method PUT -Headers $TokenHeaders -uri "https://api.spotify.com/v1/me/player/play"

}

Function Volume ($Volume) { 

    $Token = GetAccessToken

    $TokenHeaders = $Null
    $TokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $TokenHeaders.Add("Authorization", "Bearer $($Token.access_token)")

    Invoke-RestMethod -Method PUT -Headers $TokenHeaders -uri "https://api.spotify.com/v1/me/player/volume?volume_percent=$Volume"
}

Function SkipNext {

    $Token = GetAccessToken

    $TokenHeaders = $Null
    $TokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $TokenHeaders.Add("Authorization", "Bearer $($Token.access_token)")

    Invoke-RestMethod -Method Post -Headers $TokenHeaders -uri "https://api.spotify.com/v1/me/player/next"

}

Function SkipPrev {

    $Token = GetAccessToken

    $TokenHeaders = $Null
    $TokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $TokenHeaders.Add("Authorization", "Bearer $($Token.access_token)")

    Invoke-RestMethod -Method Post -Headers $TokenHeaders -uri "https://api.spotify.com/v1/me/player/previous"

}

Function CurrentlyPlaying {
    
    $Token = GetAccessToken

    $TokenHeaders = $Null
    $TokenHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $TokenHeaders.Add("Authorization", "Bearer $($Token.access_token)")

    #Currently Playing
    $Request = Invoke-RestMethod -Method GET -Headers $TokenHeaders -uri "https://api.spotify.com/v1/me/player/currently-playing"

    #Unpack Results
    $TrackName = $Request.item.name
    $Artist = $Request.item.artists.name
    $TrackDurationInSeconds = (($Request.item.duration_ms) / 1000)
    $Trackduration = [timespan]::fromseconds($TrackDurationInSeconds)
    $TrackDuration = ($TrackDuration.Minutes).tostring() + ":" + ($Trackduration.Seconds).ToString()
    $Album = $Request.item.album.name
    $AlbumReleaseDate = $Request.item.album.release_date

    #Output

    Write-Host ""
    Write-Host $TrackName "-" $Artist -ForegroundColor Red
    Write-Host "TrackLength:" $Trackduration
    Write-Host "Album:" $Album "-" $AlbumReleaseDate
    Write-Host ""

}

cls
#An eternal loop where the user is prompted with options and can enter His / Her Choices
while ( 1 -gt 0 ) {

    PromptOptions
    $Choice = PromptChoice

    if ( $Choice -like "Pause") {
        Pause
    }

    if ( $Choice -like "Play" ) {
        Resume
    }

    if ( $Choice -like "Volume*" ) {
        $VolumeLevel = $Choice -Split " " | select -Last 1
        Volume $VolumeLevel
    }
    
    if ( $Choice -like "Skip*" ) {
        
        $SkipChoice = $Choice -Split " " | select -Last 1

        if ( $SkipChoice -like "Next" ) {
            SkipNext
        }
        if ( $SkipChoice -like "Prev*" ) {
            SkipPrev
        }
    }

    if ( $Choice -like "Track" ) {
        CurrentlyPlaying
    }

    if ( $Choice -like "Cls" ) {
        #Option to clear the screen 
        cls
    }

    if ($Choice -like "Quit" ) {
        break
    }
}