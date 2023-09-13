compiler:
	bison -d -o microParser.cpp microParser.y
	flex scanner.l
	g++ microParser.cpp lex.yy.c
	g++ tinyNew.C -o tiny
clean:
	rm *.out
	rm lex.yy.c
	rm microParser.cpp
	rm microParser.hpp
	rm tiny

team:
	@echo "Team: ojasraundale \n\nOjas Raundale \n170010004@iitdh.ac.in\n\nAmeya Vadnere\n170010002@iitdh.ac.in"

