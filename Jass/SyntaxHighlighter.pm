package Jass::SyntaxHighlighter;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
BEGIN
{
    require Exporter;
    $VERSION   = 1.0;
    @ISA       = qw|Exporter|;
    @EXPORT    = qw||;
    @EXPORT_OK = qw||;
}


use strictures 1;
use v5.14;
use File::Slurp;
use Regexp::Common;
use HTML::Entities;


# called as Jass::SyntaxHighlighter::colorize(\$jass_text);
#
sub colorize
{
    my $jass_ref = shift;
    die 'expected a scalar ref' if ref $jass_ref ne 'SCALAR';

    my %css_class_for =
    (
        keyword             => 'jass-keyword',
        type                => 'jass-type',
        number              => 'jass-number',
        string              => 'jass-string',
        comment             => 'jass-comment',
        operator            => 'jass-op',
        constant            => 'jass-const',
        common_j_native     => 'jass-common-j-native',
        blizzard_j_function => 'jass-blizzard-j-function',
    );

    my $strings = extract_strings($jass_ref);
    # use DDP; p $strings;
    my $comments = extract_comments($jass_ref);
    # use DDP; p $comments;


    # the comments could have strings inside
    # try to restore them
    for my $rep_comment (keys %$comments)
    {
        my $comment = $comments->{$rep_comment};
        for my $rep_str (keys %$strings)
        {
            my $str = $strings->{$rep_str};

            if ($comment =~ m/$rep_str/)
            {
                $comment =~ s/$rep_str/$str/;
                $comments->{$rep_comment} = $comment;
            }
        }
    }


    #  <    >
    # \x3C \x3E
    $$jass_ref =~ s:
    (    <=   |   ==  |   !=   |   >= |   [-+*/=<>!]    )
    :
        qq|<span class="$css_class_for{operator}">| . encode_entities($1,"\x3C\x3E") . '</span>'
    :egx;


    $$jass_ref =~ s|\b([\d.]+)\b|<span class="$css_class_for{number}">$1</span>|g;
    $$jass_ref =~ s|\b(0x[\dA-F-a-f]+)\b|<span class="$css_class_for{number}">$1</span>|g;


    $$jass_ref =~ s:\b(true|false)\b:<span class="$css_class_for{constant}">$1</span>:g;


    $$jass_ref =~ s:'(.{1,4})':<span class="$css_class_for{number}">'$1'</span>:g;


    state $keywords =
    [
        qw|
        globals endglobals native type extends array local constant
        call function takes returns return endfunction
        loop endloop exitwhen
        if then elseif else endif set
        or and not
        debug
        |
    ];
    state $kw = join '|', @$keywords;
    $$jass_ref =~ s:\b($kw)\b:<span class="$css_class_for{keyword}">$1</span>:g;


    state $types =
    [
        qw|
        nothing integer string real boolean code handle null

        agent             event               player           widget
        unit              destructable        item             ability
        buff              force               group            trigger
        triggercondition  triggeraction       timer            location
        region            rect                boolexpr         sound
        conditionfunc     filterfunc          unitpool         itempool
        race              alliancetype        racepreference   gamestate
        igamestate        fgamestate          playerstate      playerscore
        playergameresult  unitstate           aidifficulty     eventid
        gameevent         playerevent         playerunitevent  unitevent
        limitop           widgetevent         dialogevent      unittype
        gamespeed         gamedifficulty      gametype         mapflag
        mapvisibility     mapsetting          mapdensity       mapcontrol
        playerslotstate   volumegroup         camerafield      camerasetup
        playercolor       placement           startlocprio     raritycontrol
        blendmode         texmapflags         effect           effecttype
        weathereffect     terraindeformation  fogstate         fogmodifier
        dialog            button              quest            questitem
        defeatcondition   timerdialog         leaderboard      multiboard
        multiboarditem    trackable           gamecache        version
        itemtype          texttag             attacktype       damagetype
        weapontype        soundtype           lightning        pathingtype
        image             ubersplat           hashtable
        |
    ];
    state $type = join '|', @$types;
    $$jass_ref =~ s|\b($type)\b|<span class="$css_class_for{type}">$1</span>|g;


    state $common_j_constants =
    [
        map { chomp; $_ } read_file('symbols/common_j_constants.txt', binmode => ':encoding(UTF-8)')
    ];
    state $cjc = join '|', @$common_j_constants;
    $$jass_ref =~ s:\b($cjc)\b:<span class="$css_class_for{constant}">$1</span>:g;


    state $common_j_native_functions =
    [
        map { chomp; $_ } read_file('symbols/common_j_native_functions.txt', binmode => ':encoding(UTF-8)')
    ];
    state $cjn = join '|', @$common_j_native_functions;
    $$jass_ref =~ s:\b($cjn)\b:<span class="$css_class_for{common_j_native}">$1</span>:g;


    state $blizzard_j_constants =
    [
        map { chomp; $_ } read_file('symbols/blizzard_j_constants.txt', binmode => ':encoding(UTF-8)')
    ];
    state $bjc = join '|', @$blizzard_j_constants;
    $$jass_ref =~ s:\b($bjc)\b:<span class="$css_class_for{constant}">$1</span>:g;


    state $blizzard_j_functions =
    [
        map { chomp; $_ } read_file('symbols/blizzard_j_functions.txt', binmode => ':encoding(UTF-8)')
    ];
    state $bjf = join '|', @$blizzard_j_functions;
    $$jass_ref =~ s|\b($bjf)\b|<span class="$css_class_for{blizzard_j_function}">$1</span>|g;


    # # bring back the comments
    my $rep_comment = join '|', keys %$comments;
    if ($rep_comment ne '') # if we had comments
    {
        $$jass_ref =~ s:($rep_comment):<span class="$css_class_for{comment}">$comments->{$1}</span>:g;
    }

    # # bring back the strings
    my $rep_str = join '|', keys %$strings;
    if ($rep_str ne '') # if we had strings
    {
        $$jass_ref =~ s:($rep_str):<span class="$css_class_for{string}">$strings->{$1}</span>:g;
    }


    # chomp $$jass_ref;
}


sub extract_strings
{
    my $jass_ref = shift;
    my $strings = {};

    my $string_counter = 1;
    my $rep_str = get_random_replacement('STRING__');
    while ($$jass_ref =~ s/($RE{delimited}{-delim => '"'})/${rep_str}__$string_counter/)
    {
        my $str = $1;
        # chop $str; $str = substr $str, 1;
        $strings->{"${rep_str}__$string_counter"} = $str;
        $string_counter++;
        $rep_str = get_random_replacement('STRING__');
    }

    return $strings;
}

sub extract_comments
{
    my $jass_ref = shift;
    my $comments = {};

    my $comment_counter = 1;
    my $comment_rep = get_random_replacement('COMMENT__');
    while ($$jass_ref =~ s|(//\N*)|${comment_rep}__$comment_counter|)
    {
        my $comment = $1;
        $comments->{"${comment_rep}__$comment_counter"} = $comment;
        $comment_counter++;
        $comment_rep = get_random_replacement('COMMENT__');
    }

    return $comments;
}

sub get_random_replacement
{
    my $type = shift;
    state $chars = ['A' .. 'Z', 'a' .. 'z', '0' .. '9'];
    # state $chars = ['A' .. 'Z' ];
    my $total_chars = 0+@$chars;

    my $rep = $type
            # . time
            # . '__'
            ;
    my $rep_extra_length = 32;

    for (1 .. $rep_extra_length)
    {
        $rep .= $chars->[ int(rand() * $total_chars) ];
    }

    return $rep;
}


1;
