# Included commands:
# /window togglelevel  - hide/show levels in active window
# /show_levels_all     - show levels in all windows
# /hide_levels_all     - hide levels in all windows

use strict;
use warnings;
use Irssi v1.1;
use Irssi::TextUI;
use Data::Dumper;
use vars qw($VERSION %IRSSI);

$VERSION = "0.5.0";
%IRSSI = (
          authors       => 'Jari Matilainen',
          contact       => 'vague!#irssi@freenode on irc',
          name          => 'toggle_hidelevel',
          description   => 'Toggle hidden levels on per window basis',
          licence       => "GPLv2",
          changed       => "17.09.2018 20:30 CEST"
);

my $windows;
my $processing = 0;

Irssi::command_bind('hide_levels_all' => sub {
  set_mode_all(1);
});

Irssi::command_bind('show_levels_all' => sub {
  set_mode_all(0);
});

sub set_mode_all {
  my ($mode) = @_;
  for my $win (Irssi::windows) {
    set_mode($win, $mode);
  }
}

sub set_mode {
  my ($win, $mode) = @_;
  my $lvlbits = $win->view->{hidden_level} || $windows->{$win->{refnum}}{levels};
  my $levels = Irssi::bits2level($lvlbits);
  my $val;

  $val = $levels =~ s/(\w+)/sprintf("%s%s", $mode ? '+' : '-', $1)/gre;
  $windows->{$win->{refnum}}{mode} = $mode;

  if($val) {
    $processing += 1;
    $win->command("^window hidelevel $val");
  }
}

Irssi::signal_add('message join' => sub {
  my ($server, $target, $nick) = @_;
  return unless $server->{nick} eq $nick;

  my $win = $server->window_find_item($target);
  my $levels = $win->view->{hidden_level};
  $windows->{$win->{refnum}}{levels} = $levels;
  $windows->{$win->{refnum}}{mode}   = $levels ? 1 : 0;
#  set_mode($win, 1) if $levels;
});

Irssi::signal_add('window destroyed' => sub {
  my ($win) = @_;
  delete $windows->{$win->{refnum}};
});

Irssi::signal_add('window refnum changed' => sub {
  my ($win, $old_refnum) = @_;
  $windows->{$win->{refnum}} = $windows->{$old_refnum};
  delete $windows->{$old_refnum};
});

Irssi::command_bind('window togglelevel' => sub {
  my ($args, $server, $witem) = @_;
  return unless $witem;
  set_mode($witem->window, ($windows->{$witem->window->{refnum}}{mode} // 0) ^ 1);
});

Irssi::command_bind_last('window hidelevel' => sub {
  my ($args, $server, $witem) = @_;

  if($processing) {
    $processing -= 1;
    return;
  }

  return unless $witem;

  if($args) {
    my $levels = $witem->window->view->{hidden_level};
    $windows->{$witem->window->{refnum}}{levels} = $levels;
    $windows->{$witem->window->{refnum}}{mode}   = $levels ? 1 : 0;
  }
});

Irssi::command_bind('dump_window_hash' => sub {
  for my $key (sort {$a <=> $b} keys %$windows) {
    print Data::Dumper->Dump([$key, Irssi::bits2level($windows->{$key}{levels}), $windows->{$key}{mode}], [qw(refnum levels mode)]);
  }
});

unless(Irssi::settings_get_str('window_default_hidelevel')) {
  Irssi::settings_add_level('lookandfeel', 'window_default_hidelevel', 'HIDDEN');
}

for my $win (Irssi::windows) {
  my $view = $win->view();
  my $levels = $view->{hidden_level};
  $windows->{$win->{refnum}}{levels} = $levels;
  $windows->{$win->{refnum}}{mode}   = $levels ? 1 : 0;
}
