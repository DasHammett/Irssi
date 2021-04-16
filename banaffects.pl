use strict;
use Irssi;
use Irssi::Irc;

use vars qw($VERSION %IRSSI);
$VERSION = "1.2";
%IRSSI = (
    authors     => 'Hammett',
    contact     => 'freenode #irssi',
    name        => 'banaffects_expando',
    description => 'Shows affected nicks by a ban on a new ban ' .
                   'creates an expando to be used in /format',
    url         => '',
    licence     => 'GPLv2',
    version     => $VERSION,
);

my $my_expando_variable = "";

sub ban_new {
   my ($chan, $ban) = @_;
   return unless $chan;
   my $server = $chan->{server};
   my $banmask = $ban->{ban};
   my $banuser = $ban->{setby};
   my $ownnick = $server->{nick};
   my $channel = $chan->{name};
   my $window = $server->window_find_item($channel);
   my $selfdefense = 0;
   my @matches;
   foreach my $nick ( sort ( $chan->nicks() ) ) {
      if (Irssi::mask_match_address( $banmask, $nick->{nick}, $nick->{host} )) {
         push (@matches, $nick->{nick});
      }
   }
   my $size = @matches;
   my $nicks = join(", ", @matches);
   $my_expando_variable = "affecting " . "\cc07$nicks\co";
   if ($banuser eq $ownnick and $size > 1) {
       Irssi::print($my_expando_variable)
   };
};

sub my_expando { return $my_expando_variable };
sub clear_expando { $my_expando_variable = ""; };

Irssi::expando_create("affected_nick", \&my_expando, {"ban new" => "none"});
Irssi::signal_add('ban new', \&ban_new);
Irssi::signal_add("message irc mode", \&clear_expando);
