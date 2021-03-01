package LCS::Regex;

#dummy debug instead of the log4perl
my $quiet_debug = 1;
sub debug {
    print STDERR $_[0] // 'undefined' unless $quiet_debug;
}


#working prototype
sub generate_fuzzy_regex_short {
    my ($search_string_qtd) = @_;
    my $fuzzy_regex_string = join '.*?\\', map { 
        (length($_) > 1) 
            ? substr ($_, 0, 1) .'.*?'. (join '.*?', split "", substr $_, 1)
            : $_.'.*?'
        } split /\\/, quotemeta($search_string_qtd);
    $fuzzy_regex_string =~s/^\.\*\?//;
    #debug("Fuzzy regex: $fuzzy_regex_string;");
    return $fuzzy_regex_string;
}

#production with the pretty comments
sub generate_fuzzy_regex {
    my ($search_string_qtd) = @_;
    #checking of the command is not empty is on caller

    my $fuzzy_regex_string;

    #one-line version of the code below:
    #my $fuzzy_regex_string = join '\\\\', map { join ('.*?\\', map {
    #    join ( '.*?', split ("", $_ ) )
    #} split (/\\/, $_, -1 )) } split (/.*?\\\\.*?/, quotemeta($search_string), -1);

    #we work with the quotameta of the search string string to don't mess later with quoted .*?
    #our target: some-thing 1 action => s.*?o.*?m.*?e.*?\-.*?t.*?h.*?i.*?n.*?g.*?\ .*?1.*?\ .*?a.*?c.*?t.*?i.*?o.*?n
    #also we need to consider existing "\" in the string, so "a\\c" should go as "a.*?\\.*?c"
    my @regex_real_slash_parts;
    #so first we split by existing real slashes

    # \.cmd\123 4.5.6.7 89.\ ($search_string = "\\.cmd\\123 4.5.6.7 8.\\") => ('','.cmd','123 4.5.6.7 89.','')
    #quotameta:
    #\\\.cmd\\123\ 4\.5\.6\.7\ 89\.\ ("\\\\\\.cmd\\\\123\\ 4\\.5\\.6\\.7\\ 89\\.\\\\")
    #   => ('',  '\\.cmd',  '123\\ 4\\.5\\.6\\.7\\ 89\\.',  '');
    #split limit -1 means that ending slashes will be not lost, see split default behaviour with limit 0.
    my @cmd_real_slash_parts = split (/\\\\/, $search_string_qtd, -1);
    foreach my $cmd_real_slash_part (@cmd_real_slash_parts) {
        my @regex_quoted_slash_parts;
        #second we split by slashes entered by quotameta to don't result "\." as "\.*?.*?"

        #('', '\\.cmd', '123\\ 4\\.5\\.6\\.7\\ 89\\.', '')
        # => ((''), ('', '.cmd'), ('123', ' 4', '.5', '.6', '.7', ' 89', '.'), (''))
        my @cmd_quoted_slash_parts = split (/\\/, $cmd_real_slash_part, -1 );
        foreach my $cmd_quoted_slash_part (@cmd_quoted_slash_parts) {
            #and at last we split everything to characters and join them by .*?.

            #all inacuracies in join should be fixed later by excrescent (doubled, leading, trailing) .*? removal
            #((''), ('', '.cmd'), ('123', ' 4', '.5', '.6', '.7', ' 89', '.'), (''))
            # => (
            #    (('')),
            #    ((''), ('.','c','m','d')),
            #    (('1','2','3'), (' ','4'), ('.', '5'), ('.','6'), ('.','7'), (' ','8','9'), ('.')),
            #    (''))
            #  )
            my $regex_quoted_slash_part = join ( '.*?', split ("", $cmd_quoted_slash_part ) );
            # at the end of iterations we will have arrays:
            # => (
            #    (''),
            #    ('', '..*?c.*?m.*?d'),
            #    ('1.*?2.*?3'), (' .*?4'), ('..*?5'), ('..*?6'), ('..*?7'), (' .*?8.*?9'), ('.'),
            #    ('')
            #  )
            push @regex_quoted_slash_parts, $regex_quoted_slash_part;
        }
        my $regex_real_slash_part = join ('.*?\\', @regex_quoted_slash_parts );
        # => (
        #    '',
        #    '.*?\\..*?c.*?m.*?d',
        #    '1.*?2.*?3.*?\\ .*?4.*?\\..*?5.*?\\..*?6.*?\\..*?7.*?\\ .*?8.*?9.*?\\.',
        #    ''
        #  )
        push @regex_real_slash_parts, $regex_real_slash_part;
    }
    # => '.*?\\\\.*?.*?\\..*?c.*?m.*?d.*?\\\\.*?1.*?2.*?3.*?\\ .*?4.*?\\..*?5.*?\\..*?6.*?\\..*?7.*?\\ .*?8.*?9.*?\\..*?\\\\.*?'
    #we have doubled .*? here, and also .*? at the line head. We will remove them later.
    $fuzzy_regex_string = join '.*?\\\\.*?', @regex_real_slash_parts;

    $fuzzy_regex_string =~s/^(?:\.\*\?)+|(?:\.\*\?)+$//g;
    $fuzzy_regex_string =~s/(?:\.\*\?){2,}/\.\*\?/g;

    debug("Fuzzy regex: $fuzzy_regex_string;");

    return $fuzzy_regex_string;
}

1;
