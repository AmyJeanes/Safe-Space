@{
    WikiBaseUrl = 'https://github.com/AmyJeanes/Safe-Space/wiki'
    Categories = @(
        @{ Title = 'Exterior Reference';   File = 'Exterior-Reference';   Roots = @('gmod_safespace') }
        @{ Title = 'Interior Reference';    File = 'Interior-Reference';    Roots = @('gmod_safespace_interior') }
        @{ Title = 'Dimensions Reference';  File = 'Dimensions-Reference';  Roots = @('safespace_dimensions', 'safespace_exterior_dimensions', 'safespace_interior_dimensions') }
        @{ Title = 'Settings Reference';    File = 'Settings-Reference';    Roots = @('safespace_option') }
    )
    OwnedPrefix = @('safespace_', 'gmod_safespace')
}
