.PHONY: hippoplayerupdate.lha
hippoplayerupdate.lha:
	cp ../HiP .
	cp ../HiP-debug .
	cp ../HippoPlayer.group .
	cp ../playsid.library/playsid.library .
	cp ../playsid.library/README.txt playsid.library.readme
	rm -f $@
	lha a -o5 $@ HiP HiP.info HippoPlayer.group FILE_ID.DIZ hippoplayerupdate.readme playsid.library playsid.library.readme playsid.library-kick13 playsid.library-kick13.readme
		
clean:
	rm hippoplayerupdate.lha
