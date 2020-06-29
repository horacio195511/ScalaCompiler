# compile into jasm file
for file in test/error/*.scala;
    do ./scala "$file";
done;
# compile into class file
cd javaa;

for file in ../test/error/*.jasm;
    do ./javaa "$file";
done;