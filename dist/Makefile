hippoplayerupdate.lha: ../HiP ../HippoPlayer.group FILE_ID.DIZ HiP.info hippoplayerupdate.readme
	cp ../HiP .
	cp ../HippoPlayer.group .
	rm -f $@
	lha a -o5 $@ $^

clean:
	rm hippoplayerupdate.lha
