# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [1.2] - 2020-05-18
### Added
- Median f0 excursion (valley-to-peak range)

### Changed
- F0 peak rate now is done after filtering excursions of at least 0.5 semitones
- Interpeak period SD instead of variation coefficient

### Fixed
- Better code layout and more comments
- Return "NA" if interpeak SD in null (when there is only one peak in the analysis interval)
- Terminantes script execution if Praat's version is older than 6.1.xx

## [1.1.1] - 2019-08-23
### Fixed
- Bug fixes.

## [1.1.0] - 2018-09-22
### Added
- F0 peak rate and coefficient of variation of interpeak intervals to logged measures.

## [1.0.1] - 2018-04-11
### Added
- License information.

## [1.0.0] - 2018-03-08
### Fixed
- "no interpolation" option wasn't being honored.
- Semitone-converted Pitch object being selected when Hertz unit was the correct choice.
- Errors in "interp_quad" procedure.

### Changed
- Updated style to "colon syntax".
- Semitone conversion is now done re 1 Hz.

## [0.1.0] - 2013-10-24
### Added
- Script created.
