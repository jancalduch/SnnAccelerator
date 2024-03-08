#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>
#include <inttypes.h>
#include <stdbool.h>

// MNIST images have been resized to 16x16
#define IMAGE_SIZE 10

// Each pixel on MNIST is a value from 0 to 255, stored as integers
#define PIXEL_MAX_VALUE 20

// Number of digits in the base 10 number system
#define BASE_10 10


void print_array(uint32_t array[]){
  printf("[");
  for (uint32_t i = 0; i < IMAGE_SIZE; i++) {
    printf("%" PRIu32, array[i]);
    if (i < IMAGE_SIZE - 1) {
      printf(", "); 
    }
  }
  printf("]\n\n");
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
  for (int32_t intensity = PIXEL_MAX_VALUE; intensity >= 0; intensity--) {
    for (uint32_t pixelID = 0; pixelID < IMAGE_SIZE; pixelID++) {
      if (input_array[pixelID] == (uint32_t)intensity){            
        // Store the value to the sorted array
        sorted_array[sorted_index] = pixelID;
        sorted_index++;
        if (sorted_index == IMAGE_SIZE){            
          return;
        }
      }
    }
  }
}

void counting_sort(uint32_t input_array[], uint32_t sorted_array[]) {
  // Array to store frequency of each intensity value
  uint32_t frequency[PIXEL_MAX_VALUE+1] = {0};

  // Calculate frequency of each intensity value
  for (uint32_t pixelID = 0; pixelID < IMAGE_SIZE; pixelID++) {
    frequency[input_array[pixelID]]++;
  }

  // Calculate cumulative sum of frequencies
  for (int32_t intensity = PIXEL_MAX_VALUE - 1; intensity >= 0; intensity--) {
    frequency[intensity] += frequency[intensity + 1];
  }

  // Fill sorted array using counting sort
  for (uint32_t pixelID = 0; pixelID < IMAGE_SIZE; pixelID++) {
    uint32_t intensity = input_array[pixelID];
    sorted_array[frequency[intensity] - 1] = pixelID;
    frequency[intensity]--;
  }
}

void counting_sort_radix(uint32_t input_array[], int exp, uint32_t sorted_array[]) {
  int count[BASE_10] = {0}; // Array to store count of occurrences of each digit

  // Count occurrences of digits
  for (int i = 0; i < IMAGE_SIZE; i++)
    count[(input_array[i] / exp) % BASE_10]++;

  // Adjust count array
  for (int i = BASE_10 - 2; i >= 0; i--)
    count[i] += count[i + 1];

  // Build the sorted array
  for (int i = 0; i < IMAGE_SIZE; i++) {
    sorted_array[count[(input_array[i] / exp) % BASE_10] - 1] = i;
    count[(input_array[i] / exp) % BASE_10]--;
  }
}

void radix_sort(uint32_t input_array[], uint32_t sorted_array[]) {
  // Do counting sort for every digit
  for (int exp = 1; PIXEL_MAX_VALUE / exp > 0; exp *= 10) {
    counting_sort_radix(input_array, exp, sorted_array);
  }
}

int main() {
  uint32_t image[IMAGE_SIZE];
  uint32_t sorted_indexes[IMAGE_SIZE];

  /*  Initialize each value randomly between 0 and 255. Seed the random number 
      generator to get different values each time
  */
  srand(time(NULL));
  for (uint32_t i = 0; i < IMAGE_SIZE; i++) {
    image[i] = (uint32_t)rand() % PIXEL_MAX_VALUE + 1;
  }
  print_array(image);

  /*  Start sorting the image - first solution */
  sorter(image, sorted_indexes);
  print_array(sorted_indexes); 

  /*  Start sorting the image - counting sort not stable*/
  counting_sort(image, sorted_indexes);
  print_array(sorted_indexes);

   /*  Start sorting the image - radix sort*/
  radix_sort(image, sorted_indexes);
  print_array(sorted_indexes); 

  return 0;
}
