from sys import argv

def calc_coord(col_cnt, row_cnt):
    x_coord = bin(col_cnt)[2:].zfill(9) # returns binary representation of x-pos
    y_coord = bin(row_cnt)[2:].zfill(9) # returns binary representation of x-pos
    position = x_coord + y_coord
    return position
    
def isBgTile(tile):
    return "x\"00\"" in tile or "x\"01\"" in tile or "x\"02\"" in tile

script, filename = argv
track = open(filename, 'r')
track_pos = open("free_track_pos.txt", 'a')
free_pos_cnt = 0
elems_on_row_cnt = 0
row_cnt = 0
col_cnt = 1
pos_cnt = 0

track_pos.write("------------" + filename + "------------\n")
#track_pos.write("-- Row: 0\n")

all_lines = track.readlines() #Gets a list with all lines
for lines in all_lines:
    if row_cnt != 30: # WHY THE FUCK WOULD YOU GO UP TO 30 BUT W/E
        tiles = lines.split(',') # Splits the line at ',' 
        if elems_on_row_cnt == 0:
            track_pos.write("-- Row: " + str(row_cnt) + "\n")
        else:
            elems_on_row_cnt = 0
            track_pos.write("\n-- Row: " + str(row_cnt) + "\n")
        for tile in tiles:   
            if not (col_cnt == 0 and row_cnt == 1) and isBgTile(tile): # Checks not start pos and if background 
                coord_str = calc_coord(col_cnt, row_cnt)
                track_pos.write("b\"" + coord_str + '\",')   # Adds the free pos to track_free_pos       
                elems_on_row_cnt += 1
                free_pos_cnt += 1    
                if elems_on_row_cnt % 4 == 0:
                    elems_on_row_cnt = 0
                    track_pos.write("\n")       
            if not "--" in tile:
                col_cnt += 1
        row_cnt += 1
        col_cnt = 0
    

track_pos.write("\n" + "--- Number of elements: " + str(free_pos_cnt))        

for i in range(0,3):
    track_pos.write("\n")

track_pos.close()


