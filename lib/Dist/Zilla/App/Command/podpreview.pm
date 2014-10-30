package Dist::Zilla::App::Command::podpreview;

# ABSTRACT: preview munged pod in browser

use strict;
use warnings;
use 5.010;
use Dist::Zilla::App -command;
use Carp            qw(carp croak);

sub abstract { "preview munged pod in browser" }

sub usage_desc { "dzil podpreview My::Module" }

sub validate_args
{
    my ($self, $opt, $arg) = @_;

    my ($first, @extra) = @$arg;

    $self->usage_error("please specify what you want to preview") unless $first;

    carp( "podpreview accepts a single argument, ignoring " . join ',', @extra )
        if @extra;
}

sub execute
{
    my ($self, $opt, $arg) = @_;

    $self->app->chrome->logger->mute;

    $_->before_build for @{ $self->zilla->plugins_with(-BeforeBuild) };
    $_->gather_files for @{ $self->zilla->plugins_with(-FileGatherer) };
    $_->prune_files  for @{ $self->zilla->plugins_with(-FilePruner) };
    $_->munge_files  for @{ $self->zilla->plugins_with(-FileMunger) };

    my $module = $arg->[0];
    my $colons = $module =~ s/::/\//g;
    my @filenames = "lib/$module.pm";
    push @filenames, "bin/$module", $module if !$colons;

    require List::Util;
    my $object = List::Util::first {
        my $name = $_->name;
        List::Util::first { $name eq $_ } @filenames
    } @{ $self->zilla->files };
    croak "Cannot find object " . $arg->[0] unless $object;

    require File::Temp;
    my ($fh, $filename) = File::Temp::tempfile();
    print $fh $object->content or croak $!;
    close $fh or croak $!;
    require App::PodPreview;
    App::PodPreview::podpreview($filename);
}

1;

=pod

=head1 SYNOPSIS

    dzil podpreview My::Module

=head1 DESCRIPTION

A L<Dist::Zilla> command to preview the munged pod of a module in a browser using L<App::PodPreview>.

=head1 SEE ALSO

=for :list
* L<Dist::Zilla>
* L<App::PodPreview>

