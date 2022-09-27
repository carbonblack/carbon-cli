function Disconnect-CBCServer{
    Process{
        Remove-Variable -Name CBC_AUTH_SERVER -Scope Global
        Remove-Variable -Name CBC_AUTH_ORG_KEY -Scope Global
        Remove-Variable -Name CBC_AUTH_TOKEN_KEY -Scope Global
    }
}