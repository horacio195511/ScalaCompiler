# compile into jasm file
for file in test/test/*.scala;
    do ./scala "$file";
done;
# compile into class file
cd javaa;

for file in ../test/test/*.jasm;
    do ./javaa "$file";
done;