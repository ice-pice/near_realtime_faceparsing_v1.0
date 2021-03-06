#define INF 1E20
#include <math.h>
#include <sys/types.h>
#include <stdio.h>
#include <limits.h>
#include <string.h>
#include "mex.h"

/*
 * shiftdt.cc
 * Generalized distance transforms based on Felzenswalb and Huttenlocher.
 * This applies computes a min convolution of an arbitrary quadratic function ax^2 + bx
 * This outputs results on an shifted, subsampled grid (useful for passing messages between variables in different domains)
 */

static inline int square(int x) { return x*x; }

// dt1d(source,destination_val,destination_ptr,source_step,source_length,
//      a,b,dest_shift,dest_length,dest_step)
void dt1d(double *src, double *dst, int *ptr, int step, int len, double a, double b, int dshift, int dlen, double dstep, double q1, double q2, double p1, double p2) {
  int   *v = new int[len];
  float *z = new float[len+1];
  int k = 0;
  int q = 0;
  v[0] = q1-1;
  z[0] = -INF;
  z[1] = +INF;

  for (q = q1; q <= q2-1; q++) {
    float s = ((src[q*step] - src[v[k]*step]) - b*(q - v[k]) + a*(square(q) - square(v[k]))) / (2*a*(q-v[k]));
    while (s <= z[k]) {
      k--;
      s  = ((src[q*step] - src[v[k]*step]) - b*(q - v[k]) + a*(square(q) - square(v[k]))) / (2*a*(q-v[k]));
    }
    k++;
    v[k]   = q;
    z[k]   = s;
    z[k+1] = +INF;
  }

   k = 0;
   q = dshift - 1 + p1;
//   q = p1 - 1;

   for (int i= p1-1; i <= p2-1; i++) {
     while (z[k+1] < q)
       k++;
     dst[i*step] = a*square(q-v[k]) + b*(q-v[k]) + src[v[k]*step];
     ptr[i*step] = v[k];
     q += dstep;
  }

  delete [] v;
  delete [] z;
}



// matlab entry point
// [M, Ix, Iy] = dt(vals, ax, bx, ay, by)
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  if (nrhs != 18)
    mexErrMsgTxt("Wrong number of inputs"); 
  if (nlhs != 3)
    mexErrMsgTxt("Wrong number of outputs");
  if (mxGetClassID(prhs[0]) != mxDOUBLE_CLASS)
    mexErrMsgTxt("Invalid input");

  // Read in deformation coefficients, negating to define a cost
  // Read in offsets for output grid, fixing MATLAB 0-1 indexing
  double *vals = (double *)mxGetPr(prhs[0]);
  int sizx  = mxGetN(prhs[0]);
  int sizy  = mxGetM(prhs[0]);
  double ax = -mxGetScalar(prhs[1]);
  double bx = -mxGetScalar(prhs[2]);
  double ay = -mxGetScalar(prhs[3]);
  double by = -mxGetScalar(prhs[4]);

  int lenx  = (int)mxGetScalar(prhs[7]);
  int leny  = (int)mxGetScalar(prhs[8]);
  double step = mxGetScalar(prhs[9]);
  double parx1 = mxGetScalar(prhs[10]);
  double pary1 = mxGetScalar(prhs[11]);
  double parx2 = mxGetScalar(prhs[12]);
  double pary2 = mxGetScalar(prhs[13]);
  double chlx1 = mxGetScalar(prhs[14]);
  double chly1 = mxGetScalar(prhs[15]);
  double chlx2 = mxGetScalar(prhs[16]);
  double chly2 = mxGetScalar(prhs[17]);
  int offx  = (int)mxGetScalar(prhs[5])-1;
  int offy  = (int)mxGetScalar(prhs[6])-1;


  mxArray  *mxM = mxCreateNumericMatrix(leny,lenx,mxDOUBLE_CLASS, mxREAL);
  mxArray *mxIy = mxCreateNumericMatrix(leny,lenx,mxINT32_CLASS, mxREAL);
  mxArray *mxIx = mxCreateNumericMatrix(leny,lenx,mxINT32_CLASS, mxREAL);
  double   *M = (double *)mxGetPr(mxM);
  int *Iy = (int *)mxGetPr(mxIy);
  int *Ix = (int *)mxGetPr(mxIx);

  double   *tmpM =  (double *)mxCalloc(leny*sizx, sizeof(double));
  int *tmpIy = (int *)mxCalloc(leny*sizx, sizeof(int));

//  mexPrintf("reached here\n");

//  memset(tmpM,'b',leny*sizx);
//  memset(mxM,'b',leny*lenx);
  
//  mexPrintf("memset done!\n");

  //printf("(%d,%d),(%d,%d),(%d,%d)\n",offx,offy,lenx,leny,sizx,sizy);

  // dt1d(source,destination_val,destination_ptr,source_step,source_length,
  //      a,b,dest_shift,dest_length,dest_step)
  //for (int x = 0; x < sizx; x++)
  for (int x = chlx1-1; x < chlx2; x++)
    dt1d(vals+x*sizy, tmpM+x*leny, tmpIy+x*leny, 1, sizy, ay, by, offy, leny, step, chly1, chly2, pary1, pary2);
   
  for (int y = pary1-1; y < pary2; y++)
    dt1d(tmpM+y, M+y, Ix+y, leny, sizx, ax, bx, offx, lenx, step, chlx1, chlx2, parx1, parx2);

  // get argmins and adjust for matlab indexing from 1
  for (int x = 0; x < lenx; x++) {
    for (int y = 0; y < leny; y++) {
      int p = x*leny+y;
      Iy[p] = tmpIy[Ix[p]*leny+y]+1;
      Ix[p] = Ix[p]+1;
    }
  }

  mxFree(tmpM);
  mxFree(tmpIy);
  plhs[0] = mxM;
  plhs[1] = mxIx;
  plhs[2] = mxIy;
  return;
}
