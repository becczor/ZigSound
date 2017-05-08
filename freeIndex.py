from sys import argv


def calc_coord(counter):
    x_coord = bin(counter%39)[2:]
    y_coord = bin(counter//40)[2:]
    x_zeros = (6 - len(str(x_coord)))*'0'
    y_zeros = (5 - len(str(y_coord)))*'0'
    final_coord = "000_" + x_zeros + x_coord + "_0000_" + y_zeros + y_coord
    return final_coord



script, filename = argv
track = open(filename, 'r')
track_pos = open("free_track_pos", 'a')
counter = 0;


track_pos.write("\n")
track_pos.write(" ------------ TRACK ------------ ")
track_pos.write("\n")


all_lines = track.readlines() #Gettis a list with all lines
for lines in all_lines:
    tiles = lines.split(',') # Splits the line at ',' 
    for tile in tiles:   
        if "x\"00\"" in tile: # checks if background 
            coord_str = calc_coord(counter)
            track_pos.write(coord_str)   # adds the free pos to track_free_pos 
            track_pos.write(", ")
            counter += 1
        elif "--" in tile:
            track_pos.write(tile);
        else:
            counter += 1
        

for i in range(0,5):
    track_pos.write("\n")


track_pos.close()


