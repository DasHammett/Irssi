use Irssi qw(servers);
#use warnings; 
use strict;
use File::Glob qw/:bsd_glob/;
use vars qw($VERSION %IRSSI);

$VERSION      = "0.3";

%IRSSI = (
      authors => "Hammett",
      contact => "irc-hispano",
      name => "Previously_known",
      description => "Prints previous known nick for IP" .
                     "Creates a variable 'previous_nick'" .
                     "to be used in /format in 'message join." .
                     "signal." .
                     "Autosave on server disconnected",
      license => "Public Domain",
      url => "none"
);
my %hash;
my $env = $ENV{"HOME"};
my $nickdb = $env . "/.irssi/nicks.db";

if (!-e $nickdb) {truncate $nickdb,0;};
open(my $file, "<", $nickdb) or die "Cannot open file(s)";

while (<$file>) {
   chomp;
   my @array = split /;/, $_;
   $hash{$array[0]} = $array[1];
}
close $file;

my $previous = "";

sub conv {
    my $data = $_[0];
    if (!$data) { return; }
    ($data = $data) =~ s/\]/~~/g;
    ($data = $data) =~ s/\[/@@/g;
    ($data = $data) =~ s/\^/##/g;
    ($data = $data) =~ s/\\/&&/g;
    ($data = $data) =~ s/\{/&&/g;
    ($data = $data) =~ s/\}/&&/g;
    return $data;
}

sub track_join {
    my ($server, $chan, $joined_nick, $address, $account, $realname) = @_;
    my $joined_nick= conv($joined_nick);
    my @spl   = split(/@/, $address);
    my $mask  = $spl[1] if($spl[1] !~ "QuieroChat" | $spl[1] !~ "&&");
    $previous = "";
    
    if (! (exists $hash{$mask} )) {
        $hash{$mask} = $joined_nick;
    } else {
       my @nicks_list = split(/, /,$hash{$mask});
       my @old_nicks = grep(!/^$joined_nick$/,@nicks_list);
       my $nick_in_list = grep(/^$joined_nick$/,@nicks_list);
       if (!$nick_in_list) {
          $hash{$mask} = $hash{$mask} . ", $joined_nick";
          $previous = "Previously known as: " . join(", ", @nicks_list);
       } else {
          if (@old_nicks) {
             $previous = "Previously known as: " . join(", ", @old_nicks);
          }
       }
    }
 }

sub save_to_file {
   open(FH , ">", $nickdb) or die $!;
   foreach my $key ( sort keys %hash ) {
      print FH join(";",$key,$hash{$key}) . "\n";
   }
   close(FH);
}

sub nick_changed {
    my ($server, $new_nick, $old_nick, $address) = @_;
    my $new_nick = conv($new_nick);
    my @spl   = split(/@/, $address);
    my $mask  = $spl[1] if($spl[1] !~ "QuieroChat" |  $spl[1] !~ "&&");
    my @nicks_list = split(/, /,$hash{$mask});
    my $nick_in_list = grep(/^$new_nick$/,@nicks_list);
    if (!$nick_in_list) {
       $hash{$mask} = $hash{$mask} . ", $new_nick"
    }
 }

sub my_expando { $previous };

sub search_previous {
   my ($arg, $server, $witem) = @_;
   ($arg = $arg) =~ s/\s//g;
   $arg = conv($arg);
   return unless (defined $witem && $witem->{type} eq 'CHANNEL');
   my $chan = $witem->{name};
   my $found = $witem->nick_find($arg);
   if ($found ne '') {
         my @mask_found = split(/@/,$found->{host});
         my $mask = $mask_found[1];
         my $all_matches = $hash{$mask};
         my @all_matches_split = split(/, /, $all_matches);
         my $found_nicks = join(", ", grep(!/^$arg$/, @all_matches_split));

         if ($found_nicks ne '') {
          Irssi::print("\cc03$arg\co" . " was previously known as " . "\cc04$found_nicks\co");
          } else {
              Irssi::print("No previous nicks found for " . "\cc03$arg\co")
          };
       } else {
           Irssi::print("Nick not found in channel");
    };
 }

Irssi::expando_create("previous_nick", \&my_expando, {"message join" => "none"});
Irssi::signal_add("message join", \&track_join);
Irssi::signal_add_first("server quit", \&save_to_file);
Irssi::signal_add("message nick", \&nick_changed);
Irssi::command_bind("previous_nick_save", \&save_to_file);
Irssi::command_bind("previous_nick_count", \&hash_count);
Irssi::command_bind("previous_nick", \&search_previous)
