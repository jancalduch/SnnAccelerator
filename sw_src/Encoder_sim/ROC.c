#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>
#include <inttypes.h>
#include <stdbool.h>

// MNIST images have been resized to 16x16
#define IMAGE_SIZE 256

// Each pixel on MNIST is a value from 0 to 255, stored as integers
#define PIXEL_MAX_VALUE 255


void print_array(uint32_t array[], uint32_t size){
    uint32_t i;
    printf("[");
    for (i = 0; i < size; i++) {
        printf("%" PRIu32, array[i]);
        if (i < size - 1) {
            printf(", ");
        }
    }
    printf("]\n");
}

void sorter(uint32_t input_array[], uint32_t sorted_array[]){

    /*  Encoding algorithm: O(n^2) = O(IMAGE_SIZE * PIXEL_MAX_VALUE)
        Works by iterating through each of the possible intensity values and 
        storing the pixel id of the array values that match. The inner loop 
        ensures that we check all array values. Each time a match occurs we 
        store the value and increas the pointer to the next sotring location. 
        Stop when the array has been sorted. 
    */ 
    uint32_t sorted_index = 0;
    int32_t intensity;
    uint32_t pixelID;
    for (intensity = PIXEL_MAX_VALUE; intensity >= 0; intensity--) {
        for (pixelID = 0; pixelID < IMAGE_SIZE; pixelID++) {
            if (input_array[pixelID] == (uint32_t)intensity){            
                // Here we can store the value or output to AER
                sorted_array[sorted_index] = pixelID;
                sorted_index++;
                if (sorted_index == IMAGE_SIZE){            
                    return;
                }
            }
        }
    }
}

int main() {
    uint32_t image[IMAGE_SIZE];
    uint32_t sorted_indexes[IMAGE_SIZE];

    /*  Initialize each value randomly between 0 and 255. Seed the random number 
        generator to get different values each time
    */
    uint32_t i;
    srand(time(NULL));
    for (i = 0; i < IMAGE_SIZE; i++) {
        image[i] = (uint32_t)rand() % PIXEL_MAX_VALUE + 1;
    }

    // Sort the images
    sorter(image, sorted_indexes);
    
    // Print the result
    printf("Original image: ");
    print_array(image, IMAGE_SIZE);
    printf("Encoded image: ");
    print_array(sorted_indexes, IMAGE_SIZE); 

    return 0;
}
