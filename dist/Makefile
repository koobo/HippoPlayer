.PHONY: hippoplayerupdate.lha
hippoplayerupdate.lha:
	cp ../HiP .
	cp ../HiP-debug .
	cp ../HippoPlayer.group .
	cp ../playsid.library/playsid.library .
	cp ../playsid.library/README.txt playsid.library.readme
	rm -f $@
	chmod a+rx HiP
	lha a -1 -o5 $@ HiP HiP.info HippoPlayer.group FILE_ID.DIZ hippoplayerupdate.readme playsid.library playsid.library.readme
		
clean:
	rm hippoplayerupdate.lha
