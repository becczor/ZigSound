from sys import argv

def calc_coord(position):
    x_coord = position[2:11]
    y_coord = position[11:20]
    x_transl = int(x_coord, 2)
    y_transl = int(y_coord, 2)
    coord = str(x_transl) + ',' +  str(y_transl)
    return coord

script, filename = argv
track = open(filename, 'r')
transl_pos = open("transl_free_track_pos.txt", 'a')



transl_pos.write("------------" + filename + "------------\n")
#track_pos.write("-- Row: 0\n")

all_lines = track.readlines() #Gets a list with all lines
for lines in all_lines:
        tiles = lines.split(',') # Splits the line at ',' 
        for tile in tiles:
            if (not "--" in tile) and len(tile) > 9:
                coord_str = calc_coord(tile)
                transl_pos.write("(" + coord_str + "), ")   # Adds the free pos to track_free_pos       )       
            else:
                 transl_pos.write(tile)
  
    

for i in range(0,3):
    transl_pos.write("\n")

transl_pos.close()


