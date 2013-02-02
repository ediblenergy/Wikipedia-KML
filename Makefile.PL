use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'Wikipedia-KML',
  VERSION_FROM => 'lib/Wikipedia/KML.pm',
  PREREQ_PM => {
    'Image::Size' => 0,
    'LWP::UserAgent' => 0,
  }
);
