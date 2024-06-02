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


void print_array(int array[]){
  printf("[");
  for (int i = 0; i < IMAGE_SIZE; i++) {
    printf("%d", array[i]);
    if (i < IMAGE_SIZE - 1) {
      printf(", "); 
    }
  }
  printf("]\n\n");
}

void print_indices(){
  printf("[");
  for (int i = 0; i < IMAGE_SIZE; i++) {
    printf("%d", i);
    if (i < IMAGE_SIZE - 1) {
      printf(", \t"); 
    }
  }
  printf("]\n");
}

void print_array_reverse(int array[]){
  printf("[");
  for (int i = IMAGE_SIZE - 1; i >= 0; i--) {
    printf("%d", array[i]);
    if (i > 0) {
      printf(", \t"); 
    }
  }
  printf("]\n\n");
}

void sorter(int input_array[], int sorted_array[]){

  /*  Encoding algorithm: O(n^2) = O(IMAGE_SIZE * PIXEL_MAX_VALUE)
      Works by iterating through each of the possible intensity values and 
      storing the pixel id of the array values that match. The inner loop 
      ensures that we check all array values. Each time a match occurs we 
      store the value and increas the pointer to the next sotring location. 
      Stop when the array has been sorted. 
  */ 
  int sorted_index = 0;
  for (int intensity = PIXEL_MAX_VALUE; intensity >= 0; intensity--) {
    for (int pixelID = 0; pixelID < IMAGE_SIZE; pixelID++) {
      if (input_array[pixelID] == intensity){            
        // Store the value to the sorted array (or send to AER)
        sorted_array[sorted_index] = pixelID;
        sorted_index++;
        if (sorted_index == IMAGE_SIZE){            
          return;
        }
      }
    }
  }
}

void counting_sort(int input_array[], int sorted_array[]) {
  // Array to store frequency of each intensity value
  int frequency[PIXEL_MAX_VALUE+1] = {0};

  // Calculate frequency of each intensity value
  for (int pixelID = 0; pixelID < IMAGE_SIZE; pixelID++) {
    frequency[input_array[pixelID]]++;
  }

  // Calculate cumulative sum of frequencies
  for (int intensity = 1; intensity <= PIXEL_MAX_VALUE; intensity++) {
    frequency[intensity] += frequency[intensity - 1];
  }

  // Fill sorted array using counting sort
  for (int pixelID = 0; pixelID < IMAGE_SIZE; pixelID++) {
    int intensity = input_array[pixelID];
    // Store the value to the sorted array
    sorted_array[frequency[intensity] - 1] = pixelID;
    frequency[intensity]--;
  }
}

void counting_sort_descending(int input_array[], int sorted_array[]) {
  // Array to store frequency of each intensity value
  int frequency[PIXEL_MAX_VALUE+1] = {0};

  // Calculate frequency of each intensity value
  for (int pixelID = 0; pixelID < IMAGE_SIZE; pixelID++) {
    frequency[input_array[pixelID]]++;
  }

  // Calculate cumulative sum of frequencies
  for (int intensity = PIXEL_MAX_VALUE - 1; intensity >= 0; intensity--) {
    frequency[intensity] += frequency[intensity + 1];
  }

  // Fill sorted array using counting sort
  for (int pixelID = IMAGE_SIZE - 1; pixelID >= 0; pixelID--) {
    int intensity = input_array[pixelID];
    // Store the value to the sorted array
    sorted_array[frequency[intensity] - 1] = pixelID;
    frequency[intensity]--;
  }
}


int main() {
  int image[IMAGE_SIZE] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 32, 81, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 38, 174, 244, 101, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 53, 187, 243, 239, 190, 75, 2, 0, 0, 0, 0, 0, 0, 0, 0, 25, 185, 111, 98, 219, 222, 71, 6, 0, 0, 0, 0, 0, 0, 0, 26, 120, 127, 20, 100, 228, 149, 27, 0, 0, 0, 0, 0, 0, 0, 0, 24, 214, 163, 183, 192, 227, 120, 0, 0, 0, 0, 0, 0, 0, 0, 1, 55, 164, 188, 83, 82, 170, 104, 12, 0, 0, 0, 0, 0, 0, 0, 1, 10, 35, 17, 4, 51, 185, 93, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 180, 77, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 50, 159, 98, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 24, 174, 64, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 45, 97, 38, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  int sorted_indexes[IMAGE_SIZE];

  /*  Initialize each value randomly between 0 and 255. Seed the random number 
      generator to get different values each time
  */
  // printf("Indices: \t\t");
  // print_indices();
  // srand(time(NULL));
  // for (int i = 0; i < IMAGE_SIZE; i++) {
  //   image[i] = rand() % PIXEL_MAX_VALUE + 1;
  // }
  // printf("Original image: \t");
  // print_array(image);

  /*  Start sorting the image - first solution */
  sorter(image, sorted_indexes);
  printf("Sorted indices: \t");
  print_array(sorted_indexes); 

  /*  Start sorting the image - counting sort*/
  counting_sort(image, sorted_indexes);
  printf("Counting sort: \t\t");
  print_array_reverse(sorted_indexes);

  /*  Start sorting the image - counting sort descending*/
  counting_sort_descending(image, sorted_indexes);
  // printf("Counting sort r: \t");
  print_array(sorted_indexes);

  return 0;
}
