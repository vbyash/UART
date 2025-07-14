#include <iostream>
#include <vector>
#include <string>

using namespace std;

int main()
{
int n = 3;
    // Write your code here.
    int temp, idx, counter;
    for(int i = 1; i<=n; i++){
        if(i==1){
            counter = 1;
        }
        for(int j = 1; j<=i; j++){
            cout<<counter;
            counter = counter + 1;
        }
        cout<< endl;
    }
}
