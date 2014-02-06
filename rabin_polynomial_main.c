/*
 * rabin_polynomial_main.c
 * 
 * Created by Joel Lawrence Tucci on 09-March-2011.
 * 
 * Copyright (c) 2011 Joel Lawrence Tucci
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#include "rabin_polynomial.h"
#include "rabin_polynomial_constants.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <limits.h>

//File for creating a command line application for the rabin polynomial library

void print_usage() {
    
    fprintf(stderr,"Usage: rabinfingerprint -o binary output file -w window size -a average block size -m minimum block size -x maximum block size \n");
    fprintf(stderr,"Window size must be between %u and %u\n",RAB_POLYNOMIAL_MIN_WIN_SIZE,RAB_POLYNOMIAL_MAX_WIN_SIZE);
}

/**
 * convenience function, gets the unsigned value for the given
 * parameter.  Returns 0 if there was an error(TODO: make this better!)
 */
unsigned int get_uintval_from_arg(int argc, int index,  char **argv, unsigned int lower_bound, unsigned int upper_bound) {
    
    unsigned int return_val=0;
    
    if(index + 1 <= argc - 1) {
        return_val=(unsigned int)strtoll(argv[index+1],NULL,10);
        
        if(errno == EINVAL || errno== ERANGE) {
            fprintf(stderr,"Could not parse argument %s for switch %s!\n",argv[index],argv[index+1]);
            return 0;
        }
    } else {
        fprintf(stderr,"too few arguments for option %s!\n",argv[index]);
        print_usage();
        return 0;
    }
    
    if(return_val < lower_bound || return_val > upper_bound) {
        fprintf(stderr,"%s must be between %u and %u!\n",argv[index],lower_bound,upper_bound);
        print_usage();
        return 0;
    }
    
    return return_val;
    
}


/**
 *  Checks to see if the values inputted by the user make sense
 */
int check_arg_sanity() {
    
    if(rabin_polynomial_max_block_size <= rabin_polynomial_min_block_size) {
        fprintf(stderr, "Minimum block size must be greater than maximum cache size!\n");
        return 0;
    }
    
    if(rabin_polynomial_average_block_size < rabin_polynomial_min_block_size || rabin_polynomial_average_block_size > rabin_polynomial_max_block_size) {
        fprintf(stderr, "Average block size must be between min and maximum block size(%u and %u)\n",rabin_polynomial_min_block_size,rabin_polynomial_max_block_size);
        return 0;
    }
    
    return 1;
}

void close_file_if_open(FILE *file_to_close) {
    if(file_to_close != NULL)
        fclose(file_to_close);
}

int main(int argc, char **argv) {
    
    if(argc < 2) { //No file name provided!
        print_usage();
        return -1;
    }
    
    FILE *bin_out=NULL;
    int i;
    
    //Scan every option but last one(file name)
    for(i=1;i<argc-1;i++) {
        if(strcmp(argv[i], "-w") == 0) {
            rabin_sliding_window_size=get_uintval_from_arg(argc,i,argv,RAB_POLYNOMIAL_MIN_WIN_SIZE,RAB_POLYNOMIAL_MAX_WIN_SIZE);
            if(rabin_sliding_window_size > 0)
                i++;
            else
                return -1; //Illegal value, we are done!
        } else if(strcmp(argv[i],"-m") == 0) {
            rabin_polynomial_min_block_size=get_uintval_from_arg(argc-1,i,argv,1,UINT_MAX); 
            //May eventually actually add a limit here someday
            
            if(rabin_polynomial_min_block_size > 0) 
                i++;
            else 
                return -1;
            
        } else if(strcmp(argv[i],"-x") == 0) {
            rabin_polynomial_max_block_size=get_uintval_from_arg(argc-1,i,argv,1,UINT_MAX); 
            if(rabin_polynomial_max_block_size > 0) 
                i++;
            else 
                return -1;
        } else if(strcmp(argv[i],"-x") == 0) {
            rabin_polynomial_max_block_size=get_uintval_from_arg(argc-1,i,argv,1,UINT_MAX); 
            if(rabin_polynomial_max_block_size > 0)
                i++;
            else 
                return -1;
        } else if(strcmp(argv[i],"-a") == 0) {
            rabin_polynomial_average_block_size=get_uintval_from_arg(argc-1,i,argv,1,UINT_MAX);
            if(rabin_polynomial_average_block_size > 0)
                i++;
            else
                return -1;
        } else if(strcmp(argv[i], "-o") == 0) {
            if(i+1 < argc-1 ) {
                i++;
                bin_out=fopen(argv[i],"wb+");
                if(bin_out == NULL) {
                    fprintf(stderr,"Could not open file %s for writing, error code is %d!\n",argv[i],errno);
                }
            } else {
                fprintf(stderr,"Must specify file to output to.\n");
                print_usage();
                return -1;
            }
        }
        
        else {//Usage is wrong
            print_usage();
            close_file_if_open(bin_out);
            return -1;
        }
        
    }
    
    if(!check_arg_sanity()) {
        //Bad params, close the file we may have read and exit
        close_file_if_open(bin_out);
        return -1;
    }
    
    FILE *input_file=fopen(argv[argc-1], "r+");
    
    if(input_file == NULL) {
        fprintf(stderr, "Could not open file %s for reading, error code %d!\n",argv[argc-1],errno);
        close_file_if_open(bin_out);
        return -1;
    }
    
    struct rabin_polynomial *head=get_file_rabin_polys(input_file);
    fclose(input_file);
    
    if(bin_out != NULL) {
        write_rabin_fingerprints_to_binary_file(bin_out,head);
        fclose(bin_out);
    } else {
            print_rabin_poly_list_to_file(stdout,head);
    }

    free_rabin_fingerprint_list(head);

    return 0;
}


