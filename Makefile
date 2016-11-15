all: check

check:
	$(call CHECK)

define CHECK
	for file in $(shell find spec/**/* -name "*.y*ml") ; do \
		$(call HIERA, $$file); \
	done
endef

define HIERA
  echo $(1); cat $(1) | ruby -ryaml -e "data = YAML::load(STDIN.read);" || exit 1
endef

