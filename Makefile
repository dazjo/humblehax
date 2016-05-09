all: save

clean:
	@rm -f build/* constants/* coe_code/coe_code.bin coe_code/coe_code.elf coe_code/build/*

save: coe_save/coe_constants.s coe_save/coe_macros.s coe_save/coe_rop.s coe_ropdb/$(REGION)_ropdb.txt
	@mkdir -p build constants
	@python scripts/makeHeaders.py constants/constants "FIRM_VERSION=$(FIRM_VERSION)" "COE_SLOT=$(COE_SLOT)" coe_ropdb/$(REGION)_ropdb.txt
	@cd coe_code && $(MAKE)
	@cp coe_code/coe_code.bin build/code.bin
	armips coe_save/coe_rop.s
	armips coe_save/coe_save.s
	@rm build/rop.bin
