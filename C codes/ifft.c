#include <stdio.h>
#include <math.h>

#define PI 3.142857

struct complex
{
  int real, img;
};

struct complex *ifft(struct complex *x, int R)
{
	struct complex temp;
	struct complex *y;
	int n,k;

	for(n = 0; n < R; n++)
	{	
		(y[k]).real=0;
		(y[k]).img=0;
		for(k = 0; k < R; k++)
		{
			//temp = exp(j*2*pi*(k-1)*(n-1)/R)
			temp.real = cos(2*PI*(k-1)*(n-1)/R);
			temp.img = sin(2*PI*(k-1)*(n-1)/R);
			(y[k]).real = (y[k]).real + (1/R)*x[k].real*(temp).real - (1/R)*x[k].img*(temp).img;
			(y[k]).img = (y[k]).img + (1/R)*x[k].real*(temp).img + (1/R)*x[k].img*(temp).real;
			//printf("Sum = %d + %di", (y[k]).real, (y[k]).img);
		}
	}
	return y;
}