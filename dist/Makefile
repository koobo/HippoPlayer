.PHONY: hippoplayerupdate.lha
hippoplayerupdate.lha:
	cp ../HiP .
	cp ../HiP-debug .
	cp ../HippoPlayer.group .
	rm -f $@
	lha a -o5 $@ HiP HiP.info HippoPlayer.group FILE_ID.DIZ hippoplayerupdate.readme

clean:
	rm hippoplayerupdate.lha
