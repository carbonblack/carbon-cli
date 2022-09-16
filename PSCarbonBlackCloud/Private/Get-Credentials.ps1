if (!$path1) {
    Set-Variable path1 -Option ReadOnly -Value "~/.carbonblack/credentials.cbc"
}

Function Format-IniFile ($file, $sectionName) {
    $ini = @{}
    switch -regex -file $file {
      "^\[(.+)\]$" {
        $section = $matches[1].Trim()
        $ini[$section] = @{}
      }
      "^\s*([^#].+?)\s*=\s*(.*)" {
        $name,$value = $matches[1..2]
        
        if (!($name.StartsWith(";"))) {
          $ini[$section][$name] = $value.Trim()
        }
      }
    }
    $ini[$sectionName]
  }

function Get-Credentials {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$true)]
    [string]$CBC_AUTH_AT_SECTION
    )
    Process{
        $ini = Format-IniFile $path1 $CBC_AUTH_AT_SECTION
        if($null -eq $ini)
        {
            return $null
        }
        
        $collection = @{
            "url" = $ini['url'];
            "token" = $ini['token'];
            "org" = $ini['org_key']
        }
        
        return $collection
    }
}
