import csv
 
f = open('jisutfTable.txt', 'r')
reader = csv.reader(f, delimiter=' ')
for r in reader:
    if r[5] != "------":
        print("hm.put(0x"+r[0]+",0x" + str(r[1])+");")
    else:
        print("hm.put(0x"+r[1]+",0x000000);")

                