.SECONDARY:

ifeq ($(VERBOSE),1)
SILENT:=
else
SILENT:=@
endif

IN_SCADS := $(wildcard *.scad)
IN_OBJS  := $(wildcard *.obj)
IN_STLS  := $(wildcard *.stl)
IN_3MFS  := $(wildcard *.3mf)
TARGETS  := $(IN_SCADS:.scad=) $(IN_STLS:.stl=) $(IN_OBJS:.obj=) $(IN_3MFS:.3mf=)

.PHONY: all
all: $(TARGETS) time

.PHONY: $(TARGETS)
$(TARGETS): Makefile
	$(SILENT)+$(MAKE) --no-print-directory \
		PRINTER_3D=$(shell if [ -n "$(PRINTER_3D)" ]; then echo "$(PRINTER_3D)" ;else grep -h "^PRINTER_3D=" project.config "$@.config" 2>/dev/null | tail -1 | sed 's/^[A-Z0-9_]*=//' ;fi) \
		FILAMENT=$(shell   if [ -n "$(FILAMENT)"   ]; then echo "$(FILAMENT)"   ;else grep -h "^FILAMENT="   project.config "$@.config" 2>/dev/null | tail -1 | sed 's/^[A-Z0-9_]*=//' ;fi) \
		MODE=$(shell       if [ -n "$(MODE)"       ]; then echo "$(MODE)"       ;else grep -h "^MODE="       project.config "$@.config" 2>/dev/null | tail -1 | sed 's/^[A-Z0-9_]*=//' ;fi) \
		COPIES=$(shell     if [ -n "$(COPIES)"     ]; then echo "$(COPIES)"     ;else grep -h "^COPIES="     project.config "$@.config" 2>/dev/null | tail -1 | sed 's/^[A-Z0-9_]*=//' ;fi) \
		SCALE=$(shell      if [ -n "$(SCALE)"      ]; then echo "$(SCALE)"      ;else grep -h "^SCALE="      project.config "$@.config" 2>/dev/null | tail -1 | sed 's/^[A-Z0-9_]*=//' ;fi) \
		CUSTOM_PROJECT_INI=$(shell [ -f "project.ini" ] && echo "project.ini" ) \
		CUSTOM_FILE_INI=$(shell    [ -f "$@.ini"      ] && echo "$@.ini"      ) \
		CUSTOM_CONFIG=$(shell [ -f "$@.config" ] && echo "$@.config") \
		VERBOSE=$(VERBOSE) \
		VCS_HASH=$(shell  if [ -n "$(VCS_HASH)"  ] ; then echo "$(VCS_HASH)"  ; else echo "unset" ; fi) \
		INTERNAL_RUN=1 \
		"build/$@.proxy"


ifneq ($(INTERNAL_RUN),)

SCAD_FLAGS+=-D VCS_HASH=\"$(VCS_HASH)\"
SCAD_FLAGS+=--hardwarnings
SCAD_FLAGS+=--check-parameters true
SCAD_FLAGS+=--check-parameter-ranges true

build/%.proxy: \
		build/$(PRINTER_3D)/$(FILAMENT)/$(MODE)/%.time \
		Makefile
	$(SILENT)true

build/%.stl: %.scad Makefile
	$(SILENT)echo "OPENSCAD $<"
	$(SILENT)mkdir -p "build"
	$(SILENT)openscad $(SCAD_FLAGS) -o "$@" -d "$@.d" "$<" > "$@.log" 2>&1 || { cat "$@.log" ; exit 2 ; }

build/%.stl: %.stl Makefile
	$(SILENT)echo "COPY $<"
	$(SILENT)mkdir -p "build"
	$(SILENT)cp "$<" "$@"

build/%.stl: %.obj Makefile
	$(SILENT)echo "CONVERT $<"
	$(SILENT)mkdir -p "build"
	$(SILENT)assimp export "$<" "$@" > "$@.log" 2>&1 || { cat "$@.log" ; exit 2 ; }

build/%.stl: %.3mf Makefile
	$(SILENT)echo "CONVERT $<"
	$(SILENT)mkdir -p "build"
	$(SILENT)prusa-slicer \
			--export-stl \
			--output "$@" \
			"$<" \
			> "$@.log" 2>&1 || { cat "$@.log" ; exit 2 ; }

build/$(PRINTER_3D)/$(FILAMENT)/$(MODE)/%.ini: \
		config/printer/$(PRINTER_3D)/printer.ini \
		config/printer/$(PRINTER_3D)/filament/$(FILAMENT)/filament.ini \
		config/printer/$(PRINTER_3D)/filament/$(FILAMENT)/mode/$(MODE).ini \
		$(CUSTOM_PROJECT_INI) \
		$(CUSTOM_FILE_INI)
	$(SILENT)echo "CONFIG $(notdir $@) ($(PRINTER_3D)/$(FILAMENT)/$(MODE))"
	$(SILENT)mkdir -p "$$(dirname "$@")"
	$(SILENT)merge_ini -o "$@" -i $^

build/$(PRINTER_3D)/$(FILAMENT)/$(MODE)/%.gcode: \
		build/%.stl \
		build/$(PRINTER_3D)/$(FILAMENT)/$(MODE)/%.ini \
		project.config \
		$(CUSTOM_CONFIG) \
		Makefile
	$(SILENT)echo "SLICE $(notdir $<) ($(PRINTER_3D)/$(FILAMENT)/$(MODE), N=$(COPIES), scale=$(SCALE))"
	$(SILENT)prusa-slicer \
			--load "$$(echo "$@" | sed 's/\.gcode$$/.ini/')" \
			--export-gcode \
			--output "$@" \
			--duplicate "$(COPIES)" \
			--scale "$(SCALE)" \
			"$<" \
			> "$@.log" 2>&1 || { cat "$@.log" ; exit 2 ; }

%.time: %.gcode
	$(SILENT)echo "TIME $(notdir $<) ($(PRINTER_3D)/$(FILAMENT)/$(MODE))"
	$(SILENT)grep \
			-e '^; filament used ' \
			-e '^; filament cost ' \
			-e '^; estimated .*printing time ' \
			"$<" \
			| sed 's/^; //' \
			> "$@"

include $(wildcard build/*.d)

endif


.PHONY: time
time: $(TARGETS)
	$(SILENT)find build/ -type f -name '*.time' -exec grep -H '^estimated printing time ' {} + | sort

.PHONY: clean
clean:
	$(SILENT)rm -rfv "build"
