/*
    Game of Life - 3. assembly assignment
    Kamil Tokarski, kt361223
    Usage: life input_filename no_steps
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct Game
{
    char* board; // matrix containing current game of life state. starts with
                 // extra two rows as a storage for old cells values during updates and
                 // has additional row of zeros at the top and at the bottom to simplify
                 // counting neighbours
    int width, height;
};


typedef struct Game * Game;


char last_error[1000];


extern int board_offset(int width, int height); // offset of the first cell of the actual board
extern int board_size(int width, int height); // space needed for board including all needed extra rows

extern void start(int width, int height, char *T);
extern void run();


void game_over(Game g)
{
    if(!g) {
        return;
    }
    if(g->board) {
        free(g->board);
    }
    free(g);
}

int load_level(FILE* fptr, Game g)
{
    int just_read;
    int boffset = board_offset(g->width, g->height);
    if (boffset <= 0) {
        sprintf(last_error, "Incorrect offset\n");
        return 3;
    }
    for(int i = 0; i < g->width * g->height; i++) {
        if (fscanf(fptr, "%d", &just_read) != 1) {
            sprintf(last_error, "Error on reading board value (%d)", i);
            return 1;
        }
        if (just_read != 0 && just_read != 1) {
            sprintf(last_error, "Unexpected cell value (%d)", just_read);
            return 2;
        }
        g->board[boffset + i] = just_read;
    }
    return 0;
}

Game new_game(FILE* fptr)
{
    Game g = (Game)calloc(1, sizeof(*g));
    int done = 0;

    do {
        if (!g) {
            sprintf(last_error, "Malloc failure");
            break;
        }
        if (fscanf(fptr, "%d%d", &g->width, &g->height) != 2) {
            sprintf(last_error, "Error on width, height read");
            break;
        }
        int bsize = board_size(g->width, g->height);
        if (bsize <= 0) {
            sprintf(last_error, "Incorrect size (w: %d h: %d)", g->width, g->height);
            break;
        }
        if(!(g->board = (char *)calloc(bsize, sizeof(*g->board)))) {
            sprintf(last_error, "Calloc failure");
            break;
        }
        if(load_level(fptr, g)) {
            break;
        }
        done = 1;
    }
    while(0);

    if (done) {
        return g;
    }

    game_over(g);
    return NULL;
}

void print_level(Game g)
{
    int boffset = board_offset(g->width, g->height);
    for(int i = 0; i < g->width * g->height; i++) {
        if (i % g->width == 0) {
            printf("\n");
        }
        //printf("%d ", g->board[boffset + i]);
        printf(g->board[boffset + i]? "*" : " ");
    }
}

int main(int argv, char** argc)
{
    FILE* fptr = NULL;
    Game g = NULL;
	
    do {
        int no_steps;
        if (argv != 3) {
            sprintf(last_error, "Usage: %s filename no_steps\n", argc[0]);
            break;
        }
        if ((no_steps = atoi(argc[2])) <= 0) {
            sprintf(last_error, "Expected positive number of steps, got %d\n", no_steps);
            break;
        }
        fptr = fopen(argc[1], "r");
        if (!fptr) {
            sprintf(last_error, "Could not open file '%s'", argc[1]);
            break;
        }
        if (!(g = new_game(fptr))) {
            break;
        }

        start(g->width, g->height, g->board);
        for (int i = 1; i <= no_steps; i++) {
            run();
            print_level(g);
            if (i != no_steps) {
                printf("\n");
            }
            while (getchar() != '\n');
        }
    }
    while (0);

    game_over(g);

    if (fptr) {
        if (fclose(fptr)) {
            sprintf(last_error, "Error while closing the file");
        }
    }

    if (strlen(last_error)) {
        printf("%s\n", last_error);
    }

    return 0;
}
