clean:
	rm *~
	rm views/*~
	return 0

commit:
	git add .
	git commit -m "autosave"

save: commit
	git push origin
