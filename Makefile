clean:
	rm *~
	rm views/*~

commit:
	git add .
	git commit -m "autosave"

save: commit
	git push origin
