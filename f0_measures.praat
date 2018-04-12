# Collect F0 measures
# ===================
# 
# Collects a set of descriptive measures of F0 from Pitch objects
# paired with TextGrids. Measures will be collected for every
# non-empty interval in a selected tier.
#
# Pablo Arantes <pabloarantes@gmail.com>
#
# # Changelog:
# - 2013-10-24: created
# - 2018-03-08: "no interpolation" option wasn't being honored; fixed semitone-converted Pitch
#     object being selected when Hertz unit was the correct choice; updated style to "colon syntax";
#     fixed errors in "interp_quad" procedure; semitone conversion is now done re 1 Hz.
# - 2018-04-11: added license information.
#
# Copyright (C) 2013-2018 Pablo Arantes
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# A copy of the GNU General Public License is available at
# <http://www.gnu.org/licenses/>.

form F0 measures
	sentence Pitch_folder /folderName/
	sentence Grid_folder /folderName/
	sentence Report /folderName/report.txt
	natural Tier 1
	real Smooth 0 (= no smooth)
	optionmenu Interpolation: 1
		button None
		button Quadratic
		button Linear
	optionmenu Units: 1
		button Both
		button Hertz
		button Semitones
	optionmenu Separator: 1
		button Tab
		button Comma
		button Single space
endform

if separator = 1
	sep$ = tab$
elsif separator = 2
	sep$ = ","
else
	sep$ = " "
endif

# Report file header
## Hertz units
header_hz$ = "mean_hz" + sep$ + "median_hz" + sep$ + "baseline_hz" + sep$ + "sd_hz" + sep$ + "cv_hz" + sep$ + "qcd_hz" + sep$ + "mad_hz" + sep$ + "basedev_hz" + sep$ + "mean_to_base_hz"

## Semitones units
header_st$ = "range_st" + sep$ +  "mean_st" + sep$ + "median_st" + sep$ + "baseline_st" + sep$ + "sd_st" + sep$ + "cv_st" + sep$ + "qcd_st" + sep$ + "mad_st" + sep$ + "basedev_st" + sep$ + "mean_to_base_st"

if units = 1
	header$ = header_hz$ + sep$ + header_st$
elsif units = 2
	header$ = header_hz$
else
	header$ = header_st$
endif

deleteFile: report$
writeFileLine: report$, "filename", sep$, "label", sep$, header$ 

# List of Pitch files to be processed
list = Create Strings as file list: "pitch_files", pitch_folder$ + "*.Pitch"
files = Get number of strings

# Keep track of TextGrids with empty selected intervals
empty = 0
empty$ = ""

for file to files
	pitch$ = object$[list, file]
	pitch = Read from file: pitch_folder$ + pitch$

	# Pitch object processing
	## Smoothing
	if smooth <> 0
		selectObject: pitch
		sm = Smooth: smooth
		# Remove raw object and reassign 'pitch' to smoothed object ID
		removeObject: pitch
		pitch = sm
	endif

	## Interpolation
	if interpolation = 2
		@interp_quad: pitch
		# Remove uninterpolated object and reassign 'pitch' to interpolated object ID
		removeObject: pitch
		pitch = interp_quad.out
	elsif interpolation = 3
		interp = Interpolate
		# Remove uninterpolated object and reassign 'pitch' to interpolated object ID
		removeObject: pitch
		pitch = interp
	endif

	grid$ = selected$("Pitch") + ".TextGrid"

	# Throw message error if unable to find TextGrid file matching Pitch file
	readable = fileReadable(grid_folder$ + grid$)
	if readable = 0
		exitScript: "Could not find ", grid$, "at ", grid_folder$, "."
	endif

	grid = Read from file: grid_folder$ + grid$
	file$ = selected$("TextGrid")
	is_inter_tier = Is interval tier: tier
	if is_inter_tier = 0
		exitScript: "Tier ", tier, "in TextGrid ", file$, "is not an interval tier."
	endif

	sel = Extract one tier: tier
	tab = Down to Table: "no", 6, "no", "no"
	n = Get number of rows
	# Process only tiers with at least one non-empty intervals
    if n = 0
		# Collect info about empty tiers
        empty += 1
        empty$ = empty$ + "'empty') " + file$ + newline$
	else
		for i to n
			label$ = object$[tab, i, 2]
			start = object[tab, i, 1]
			end = object[tab, i, 3]

			if (units = 1) or (units = 2)
				# Measures in Hertz
				# -----------------
				selectObject: pitch

				# Mean
				mean_hz = Get mean: start, end, "Hertz"
				mean_hz$ = fixed$(mean_hz, 1)

				# Median
				median_hz = Get quantile: start, end, 0.5, "Hertz"
				median_hz$ = fixed$(median_hz, 1)

				# Baseline
				baseline_hz = Get quantile: start, end, 0.074, "Hertz"
				baseline_hz$ = fixed$(baseline_hz, 1)

				# Standard deviation
				sd_hz = Get standard deviation: start, end, "Hertz"
				sd_hz$ = fixed$(sd_hz, 1)

				# Coefficient of variation
				cv_hz$ = fixed$(sd_hz / mean_hz * 100, 1)

				# Quartile coefficient of dispersion
				q1_hz = Get quantile: start, end, 0.25, "Hertz"
				q3_hz = Get quantile: start, end, 0.75, "Hertz"
				qcd_hz = (q3_hz - q1_hz) / (q3_hz + q1_hz)
				qcd_hz$ = fixed$(qcd_hz * 100, 1)

				# Median absolute deviation
				selectObject: pitch
				pitch_mad = Copy: "mad"
				Formula: "if self <> 0 then abs(self - median_hz) else 0 endif"
				mad_hz = Get quantile: start, end, 0.5, "Hertz"
				mad_hz$ = fixed$(mad_hz, 1)
				removeObject: pitch_mad
				
				# Median absolute deviation from baseline
				selectObject: pitch
				pitch_basedev = Copy: "basedev"
				Formula: "if self <> 0 then abs(self - baseline_hz) else 0 endif"
				basedev_hz = Get quantile: start, end, 0.5, "Hertz"
				basedev_hz$ = fixed$(basedev_hz, 1)
				removeObject: pitch_basedev

				# Mean - baseline
				mean_to_base_hz$ = fixed$(mean_hz - baseline_hz, 1)

				# Join results in a string
				data_hz$ = mean_hz$ + sep$ + median_hz$ + sep$ + baseline_hz$ + sep$ + sd_hz$ + sep$ + cv_hz$ + sep$ + qcd_hz$ + sep$ + mad_hz$ + sep$ + basedev_hz$ + sep$ + mean_to_base_hz$
			endif
			
			if (units = 1) or (units = 3)
				# Measures in semitones
				# ---------------------

				selectObject: pitch
				pitch_name$ = selected$("Pitch")

				# Range (in semitones)
				minf0 = Get minimum: start, end, "Hertz", "Parabolic"
				maxF0 = Get maximum: start, end, "Hertz", "Parabolic"
				range_st =  log2(maxF0 / minf0) * 12
				range_st$ = fixed$(range_st, 2)

				# Mean
				mean_st = Get mean: start, end, "semitones re 1 Hz"
				mean_st$ = fixed$(mean_st, 2)

				# Median
				median_st = Get quantile: start, end, 0.5, "semitones re 1 Hz"
				median_st$ = fixed$(median_st, 2)

				# Baseline
				baseline_st = Get quantile: start, end, 0.074, "semitones re 1 Hz"
				baseline_st$ = fixed$(baseline_st, 2)

				# Standard deviation
				sd_st = Get standard deviation: start, end, "semitones"
				sd_st$ = fixed$(sd_st, 2)

				# Coefficient of variation
				cv_st$ = fixed$(sd_st / mean_st * 100, 1)

				# Quartile coefficient of dispersion
				q1_st = Get quantile: start, end, 0.25, "semitones re 1 Hz"
				q3_st = Get quantile: start, end, 0.75, "semitones re 1 Hz"
				qcd_st = (q3_st - q1_st) / (q3_st + q1_st)
				qcd_st$ = fixed$(qcd_st * 100, 1)

				# Convert the Pitch object to semitones relative to 1 Hz
				pitch_st = Copy: pitch_name$ + "_st"
				Formula: "log2(self / 1) * 12"

				# Median absolute deviation
				selectObject: pitch_st
				pitch_mad = Copy: pitch_name$ + "mad_st"
				Formula: "if self <> 0 then abs(self - median_st) else 0 endif"
				mad_st = Get quantile: start, end, 0.5, "Hertz"
				mad_st$ = fixed$(mad_st, 2)
				removeObject: pitch_mad

				# Median absolute deviation from baseline
				selectObject: pitch_st
				pitch_basedev_st = Copy: pitch_name$ + "basedev"
				Formula: "if self <> 0 then abs(self - baseline_st) else 0 endif"
				basedev_st = Get quantile: start, end, 0.5, "Hertz"
				basedev_st$ = fixed$(basedev_st, 2)
				removeObject: pitch_basedev_st

				# Mean - baseline
				mean_to_base_st$ = fixed$(mean_st - baseline_st, 2)

				# Join results in a strings
				data_st$ = range_st$ + sep$ + mean_st$ + sep$ + median_st$ + sep$ + baseline_st$ + sep$ + sd_st$ + sep$ + cv_st$ + sep$ + qcd_st$ + sep$ + mad_st$ + sep$ + basedev_st$ + sep$ + mean_to_base_st$
			endif

			if (units = 1) or (units = 3)
				removeObject: pitch_st
			endif

			# Write results to report file
			# ----------------------------

			if units = 1
				appendFileLine: report$, file$, sep$, label$, sep$, data_hz$, sep$, data_st$
			elsif units = 2
				appendFileLine: report$, file$, sep$, label$, sep$, data_hz$
			else
				appendFileLine: report$, file$, sep$, label$, sep$, data_st$
			endif
		endfor

	endif
	removeObject: grid, sel, tab, pitch
endfor

removeObject: list
writeInfo: "Finished at ", date$()

procedure interp_quad: .pitch
# Interpolate quadratically unvoiced periods in a Pitch object.
# Does not perform constant extrapolation at the edges.
#
# Arguments
# .pitch: [integer] id of Pitch to be interpolated

	selectObject: .pitch
	.minf0 = Get minimum: 0, 0, "Hertz", "Parabolic"
	.maxf0 = Get maximum: 0, 0, "Hertz", "Parabolic"
	.ptier = Down to PitchTier
	.points = Get number of points
	.first = Get time from index: 1
	.last = Get time from index: .points
	Interpolate quadratically: 4, "Semitones"
	.out = To Pitch: 0.01, 0.95 * .minf0, 1.05 * .maxf0
	# Unvoice the edges
	Formula: "if x < .first or x > .last then 0 else self endif"
	removeObject: .ptier
endproc
