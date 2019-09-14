//+------------------------------------------------------------------+
//|                                                   statistics.mqh |
//|            Copyright 2003-2012 Sergey Bochkanov (ALGLIB project) |
//|                   Copyright 2012-2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//| Implementation of ALGLIB library in MetaQuotes Language 5        |
//|                                                                  |
//| The features of the library include:                             |
//| - Linear algebra (direct algorithms, EVD, SVD)                   |
//| - Solving systems of linear and non-linear equations             |
//| - Interpolation                                                  |
//| - Optimization                                                   |
//| - FFT (Fast Fourier Transform)                                   |
//| - Numerical integration                                          |
//| - Linear and nonlinear least-squares fitting                     |
//| - Ordinary differential equations                                |
//| - Computation of special functions                               |
//| - Descriptive statistics and hypothesis testing                  |
//| - Data analysis - classification, regression                     |
//| - Implementing linear algebra algorithms, interpolation, etc.    |
//|   in high-precision arithmetic (using MPFR)                      |
//|                                                                  |
//| This file is free software; you can redistribute it and/or       |
//| modify it under the terms of the GNU General Public License as   |
//| published by the Free Software Foundation (www.fsf.org); either  |
//| version 2 of the License, or (at your option) any later version. |
//|                                                                  |
//| This program is distributed in the hope that it will be useful,  |
//| but WITHOUT ANY WARRANTY; without even the implied warranty of   |
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the     |
//| GNU General Public License for more details.                     |
//+------------------------------------------------------------------+
#include "ap.mqh"
#include "alglibinternal.mqh"
#include "linalg.mqh"
#include "specialfunctions.mqh"
//+------------------------------------------------------------------+
//| basic statistics methods                                         |
//+------------------------------------------------------------------+
class CBaseStat
  {
public:
                     CBaseStat(void);
                    ~CBaseStat(void);
   //--- basic parameters
   static bool       SampleMoments(const double &cx[],const int n,double &mean,double &variance,double &skewness,double &kurtosis);
   static bool       SampleAdev(const double &cx[],const int n,double &adev);
   static bool       SampleMedian(const double &cx[],const int n,double &median);
   static bool       SamplePercentile(const double &cx[],const int n,const double p,double &v);
   //--- covariance and correlation
   static double     Cov2(const double &cx[],const double &cy[],const int n);
   static double     PearsonCorr2(const double &cx[],const double &cy[],const int n);
   static double     SpearmanCorr2(const double &cx[],const double &cy[],const int n);
   static bool       CovM(const CMatrixDouble &cx,const int n,const int m,CMatrixDouble &c);
   static bool       PearsonCorrM(const CMatrixDouble &cx,const int n,const int m,CMatrixDouble &c);
   static bool       SpearmanCorrM(const CMatrixDouble &cx,const int n,const int m,CMatrixDouble &c);
   static bool       CovM2(const CMatrixDouble &cx,const CMatrixDouble &cy,const int n,const int m1,const int m2,CMatrixDouble &c);
   static bool       PearsonCorrM2(const CMatrixDouble &cx,const CMatrixDouble &cy,const int n,const int m1,const int m2,CMatrixDouble &c);
   static bool       SpearmanCorrM2(const CMatrixDouble &cx,const CMatrixDouble &cy,const int n,const int m1,const int m2,CMatrixDouble &c);
   //--- obsolete functions
   static double     PearsonCorrelation(const double &x[],const double &y[],const int n);
   static double     SpearmanRankCorrelation(const double &x[],const double &y[],const int n);
  };
//+------------------------------------------------------------------+
//| Constructor without parameters                                   |
//+------------------------------------------------------------------+
CBaseStat::CBaseStat(void)
  {

  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CBaseStat::~CBaseStat(void)
  {

  }
//+------------------------------------------------------------------+
//| Calculation of the distribution moments: mean, variance,         |
//| skewness, kurtosis.                                              |
//| INPUT PARAMETERS:                                                |
//|     X       -   sample                                           |
//|     N       -   N>=0, sample size:                               |
//|                 * if given, only leading N elements of X are     |
//|                   processed                                      |
//|                 * if not given, automatically determined from    |
//|                   size of X                                      |
//| OUTPUT PARAMETERS                                                |
//|     Mean    -   mean.                                            |
//|     Variance-   variance.                                        |
//|     Skewness-   skewness (if variance<>0; zero otherwise).       |
//|     Kurtosis-   kurtosis (if variance<>0; zero otherwise).       |
//+------------------------------------------------------------------+
static bool CBaseStat::SampleMoments(const double &cx[],const int n,double &mean,
                                     double &variance,double &skewness,double &kurtosis)
  {
//--- check
   if(!CAp::Assert(n>=0,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Len(cx)>=n,__FUNCTION__+": length(x)<n"))
      return(false);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteVector(cx,n),__FUNCTION__+": x is not finite vector"))
      return(false);
//--- create variables
   double v=0;
   double v1=0;
   double v2=0;
   double stddev=0;
//--- Init, special case 'N=0'
   mean=0;
   variance=0;
   skewness=0;
   kurtosis=0;
//--- check
   if(n<=0)
      return(true);
//--- Mean
   for(int i=0;i<n;i++)
      mean+=cx[i];
   mean/=n;
//--- Variance (using corrected two-pass algorithm)
   if(n!=1)
     {
      //--- calculation
      for(int i=0;i<n;i++)
         v1+=CMath::Sqr(cx[i]-mean);
      for(int i=0;i<n;i++)
         v2+=cx[i]-mean;
      v2=CMath::Sqr(v2)/n;
      variance=(v1-v2)/(n-1);
      //--- calculation
      stddev=MathSqrt(variance);
     }
   else
      variance=EMPTY_VALUE;
//--- Skewness and kurtosis
   if(stddev!=0)
     {
      //--- calculation
      for(int i=0;i<n;i++)
        {
         v=(cx[i]-mean)/stddev;
         v2=CMath::Sqr(v);
         skewness+=v2*v;
         kurtosis+=CMath::Sqr(v2);
        }
      //--- change values
      skewness=skewness/n;
      kurtosis=kurtosis/n-3;
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| ADev                                                             |
//| Input parameters:                                                |
//|     X   -   sample                                               |
//|     N   -   N>=0, sample size:                                   |
//|             * if given, only leading N elements of X are         |
//|               processed                                          |
//|             * if not given, automatically determined from size   |
//|               of X                                               |
//| Output parameters:                                               |
//|     ADev-   ADev                                                 |
//+------------------------------------------------------------------+
static bool CBaseStat::SampleAdev(const double &cx[],const int n,
                                  double &adev)
  {
//--- check
   if(!CAp::Assert(n>=0,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Len(cx)>=n,__FUNCTION__+": length(x)<n"))
      return(false);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteVector(cx,n),__FUNCTION__+": x is not finite vector"))
      return(false);
//--- initialization
   double mean=0;
   adev=0;
//--- check
   if(n<=0)
      return(true);
//--- Mean
   for(int i=0;i<n;i++)
      mean+=cx[i];
   mean/=n;
//--- ADev
   for(int i=0;i<n;i++)
      adev+=MathAbs(cx[i]-mean);
   adev/=n;
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Median calculation.                                              |
//| Input parameters:                                                |
//|     X   -   sample (array indexes: [0..N-1])                     |
//|     N   -   N>=0, sample size:                                   |
//|             * if given, only leading N elements of X are         |
//|               processed                                          |
//|             * if not given, automatically determined from size   |
//|               of X                                               |
//| Output parameters:                                               |
//|     Median                                                       |
//+------------------------------------------------------------------+
static bool CBaseStat::SampleMedian(const double &cx[],const int n,
                                    double &median)
  {
//--- check
   if(!CAp::Assert(n>=0,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Len(cx)>=n,__FUNCTION__+": length(x)<n"))
      return(false);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteVector(cx,n),__FUNCTION__+": x is not finite vector"))
      return(false);
//--- Some degenerate cases
   median=0;
//--- check
   if(n<=0)
      return(true);
//--- check
   if(n==1)
     {
      median=cx[0];
      return(true);
     }
//--- check
   if(n==2)
     {
      median=0.5*(cx[0]+cx[1]);
      return(true);
     }
//--- Common case, N>=3.
//--- Choose X[(N-1)/2]
   int    i=0;
   int    ir=n-1;
   int    j=0;
   int    l=0;
   int    midp=0;
   int    k=(n-1)/2;
   double a=0;
   double tval=0;
//--- create copy
   double x[];
   ArrayResizeAL(x,n);
   for(int ii=0;ii<n;ii++)
      x[ii]=cx[ii];
//--- if n>=3
   while(true)
     {
      //--- check
      if(ir<=l+1)
        {
         //--- 1 or 2 elements in partition
         if(ir==l+1 && x[ir]<x[l])
           {
            //--- swap
            tval=x[l];
            x[l]=x[ir];
            x[ir]=tval;
           }
         //--- break the cycle
         break;
        }
      else
        {
         midp=(l+ir)/2;
         //--- swap
         tval=x[midp];
         x[midp]=x[l+1];
         x[l+1]=tval;
         //--- check
         if(x[l]>x[ir])
           {
            //--- swap
            tval=x[l];
            x[l]=x[ir];
            x[ir]=tval;
           }
         //--- check
         if(x[l+1]>x[ir])
           {
            //--- swap
            tval=x[l+1];
            x[l+1]=x[ir];
            x[ir]=tval;
           }
         //--- check
         if(x[l]>x[l+1])
           {
            //--- swap
            tval=x[l];
            x[l]=x[l+1];
            x[l+1]=tval;
           }
         //--- change values
         i=l+1;
         j=ir;
         a=x[l+1];
         //--- cycle
         while(true)
           {
            //--- i++
            do
               i++;
            while(x[i]<a);
            //--- j--
            do
               j--;
            while(x[j]>a);
            //--- check
            if(j<i)
               break;
            //--- swap
            tval=x[i];
            x[i]=x[j];
            x[j]=tval;
           }
         //--- change array
         x[l+1]=x[j];
         x[j]=a;
         //--- check
         if(j>=k)
            ir=j-1;
         //--- check
         if(j<=k)
            l=i;
        }
     }
//--- If N is odd, return result
   if(n%2==1)
     {
      median=x[k];
      return(true);
     }
   a=x[n-1];
   for(i=k+1;i<n;i++)
      if(x[i]<a)
         a=x[i];
   median=0.5*(x[k]+a);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Percentile calculation.                                          |
//| Input parameters:                                                |
//|     X   -   sample (array indexes: [0..N-1])                     |
//|     N   -   N>=0, sample size:                                   |
//|             * if given, only leading N elements of X are         |
//|               processed                                          |
//|             * if not given, automatically determined from size   |
//|               of X                                               |
//|     P   -   percentile (0<=P<=1)                                 |
//| Output parameters:                                               |
//|     V   -   percentile                                           |
//+------------------------------------------------------------------+
static bool CBaseStat::SamplePercentile(const double &cx[],const int n,
                                        const double p,double &v)
  {
//--- check
   if(!CAp::Assert(n>=0,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Len(cx)>=n,__FUNCTION__+": length(x)<n"))
      return(false);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteVector(cx,n),__FUNCTION__+": x is not finite vector"))
      return(false);
//--- check
   if(!CAp::Assert(CMath::IsFinite(p),__FUNCTION__+": incorrect p"))
      return(false);
//--- check
   if(!CAp::Assert(p>=0 && p<=1,__FUNCTION__+": incorrect p"))
      return(false);
//--- check
   if(p==0)
     {
      v=cx[0];
      return(true);
     }
//--- check
   if(p==1)
     {
      v=cx[n-1];
      return(true);
     }
//--- initialization
   int    i1=0;
   double t=0;
   double rbuf[];
   v=0;
//--- create copy
   double x[];
   ArrayResizeAL(x,n);
   for(int ii=0;ii<n;ii++)
      x[ii]=cx[ii];
//--- sort
   CTSort::TagSortFast(x,rbuf,n);
//--- calculation
   t=p*(n-1);
   i1=(int)MathFloor(t);
   t=t-(int)MathFloor(t);
   v=x[i1]*(1-t)+x[i1+1]*t;
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| 2-sample covariance                                              |
//| Input parameters:                                                |
//|     X       -   sample 1 (array indexes: [0..N-1])               |
//|     Y       -   sample 2 (array indexes: [0..N-1])               |
//|     N       -   N>=0, sample size:                               |
//|                 * if given, only N leading elements of X/Y are   |
//|                   processed                                      |
//|                 * if not given, automatically determined from    |
//|                   input sizes                                    |
//| Result:                                                          |
//|     covariance (zero for N=0 or N=1)                             |
//+------------------------------------------------------------------+
static double CBaseStat::Cov2(const double &cx[],const double &cy[],
                              const int n)
  {
//--- check
   if(!CAp::Assert(n>=0,__FUNCTION__+": the error variable"))
      return(EMPTY_VALUE);
//--- check
   if(!CAp::Assert(CAp::Len(cx)>=n,__FUNCTION__+": length(x)<n"))
      return(EMPTY_VALUE);
//--- check
   if(!CAp::Assert(CAp::Len(cy)>=n,__FUNCTION__+": length(y)<n"))
      return(EMPTY_VALUE);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteVector(cx,n),__FUNCTION__+": x is not finite vector"))
      return(EMPTY_VALUE);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteVector(cy,n),__FUNCTION__+": y is not finite vector"))
      return(EMPTY_VALUE);
//--- Special case
   if(n<=1)
      return(0);
//--- create variables
   double result=0;
   double xmean=0;
   double ymean=0;
   double v=1.0/(double)n;
   double x0=cx[0];
   double y0=cy[0];
   double s=0;
   bool   samex=true;
   bool   samey=true;
//--- Additonally we calculate SameX and SameY -
//--- flag variables which are set to True when
//--- all X[] (or Y[]) contain exactly same value.
//--- If at least one of them is True, we return zero
//--- (othwerwise we risk to get nonzero covariation
//--- because of roundoff).
   for(int i=0;i<n;i++)
     {
      s=cx[i];
      samex=samex && s==x0;
      xmean+=s*v;
      s=cy[i];
      samey=samey && s==y0;
      ymean+=s*v;
     }
//--- check
   if(samex || samey)
      return(0);
//--- covariance
   v=1.0/(double)(n-1);
   for(int i=0;i<n;i++)
      result+=v*(cx[i]-xmean)*(cy[i]-ymean);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Pearson product-moment correlation coefficient                   |
//| Input parameters:                                                |
//|     X       -   sample 1 (array indexes: [0..N-1])               |
//|     Y       -   sample 2 (array indexes: [0..N-1])               |
//|     N       -   N>=0, sample size:                               |
//|                 * if given, only N leading elements of X/Y are   |
//|                   processed                                      |
//|                 * if not given, automatically determined from    |
//|                   input sizes                                    |
//| Result:                                                          |
//|     Pearson product-moment correlation coefficient               |
//|     (zero for N=0 or N=1)                                        |
//+------------------------------------------------------------------+
static double CBaseStat::PearsonCorr2(const double &cx[],const double &cy[],
                                      const int n)
  {
//--- check
   if(!CAp::Assert(n>=0,__FUNCTION__+": the error variable"))
      return(EMPTY_VALUE);
//--- check
   if(!CAp::Assert(CAp::Len(cx)>=n,__FUNCTION__+": length(x)<n"))
      return(EMPTY_VALUE);
//--- check
   if(!CAp::Assert(CAp::Len(cy)>=n,__FUNCTION__+": length(y)<n"))
      return(EMPTY_VALUE);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteVector(cx,n),__FUNCTION__+": x is not finite vector"))
      return(EMPTY_VALUE);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteVector(cy,n),__FUNCTION__+": y is not finite vector"))
      return(EMPTY_VALUE);
//--- Special case
   if(n<=1)
      return(0);
//--- create variables
   double xmean=0;
   double ymean=0;
   double v=1.0/(double)n;
   double x0=cx[0];
   double y0=cy[0];
   double s=0;
   double xv=0;
   double yv=0;
   double t1=0;
   double t2=0;
   bool   samex=true;
   bool   samey=true;
//--- Additonally we calculate SameX and SameY -
//--- flag variables which are set to True when
//--- all X[] (or Y[]) contain exactly same value.
//--- If at least one of them is True, we return zero
//--- (othwerwise we risk to get nonzero correlation
//--- because of roundoff).
   for(int i=0;i<n;i++)
     {
      s=cx[i];
      samex=samex && s==x0;
      xmean+=s*v;
      s=cy[i];
      samey=samey && s==y0;
      ymean+=s*v;
     }
//--- check
   if(samex || samey)
      return(0);
//--- calculation
   s=0;
   for(int i=0;i<n;i++)
     {
      t1=cx[i]-xmean;
      t2=cy[i]-ymean;
      xv+=CMath::Sqr(t1);
      yv+=CMath::Sqr(t2);
      s+=t1*t2;
     }
//--- check
   if(xv==0 || yv==0)
      return(0);
//--- return result
   return(s/(MathSqrt(xv)*MathSqrt(yv)));
  }
//+------------------------------------------------------------------+
//| Spearman's rank correlation coefficient                          |
//| Input parameters:                                                |
//|     X       -   sample 1 (array indexes: [0..N-1])               |
//|     Y       -   sample 2 (array indexes: [0..N-1])               |
//|     N       -   N>=0, sample size:                               |
//|                 * if given, only N leading elements of X/Y are   |
//|                   processed                                      |
//|                 * if not given, automatically determined from    |
//|                   input sizes                                    |
//| Result:                                                          |
//|     Spearman's rank correlation coefficient                      |
//|     (zero for N=0 or N=1)                                        |
//+------------------------------------------------------------------+
static double CBaseStat::SpearmanCorr2(const double &cx[],const double &cy[],
                                       const int n)
  {
//--- check
   if(!CAp::Assert(n>=0,__FUNCTION__+": the error variable"))
      return(EMPTY_VALUE);
//--- check
   if(!CAp::Assert(CAp::Len(cx)>=n,__FUNCTION__+": length(x)<n"))
      return(EMPTY_VALUE);
//--- check
   if(!CAp::Assert(CAp::Len(cy)>=n,__FUNCTION__+": length(y)<n"))
      return(EMPTY_VALUE);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteVector(cx,n),__FUNCTION__+": x is not finite vector"))
      return(EMPTY_VALUE);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteVector(cy,n),__FUNCTION__+": y is not finite vector"))
      return(EMPTY_VALUE);
//--- Special case
   if(n<=1)
      return(0);
//--- create copy
   double x[];
   double y[];
   ArrayResizeAL(x,n);
   ArrayResizeAL(y,n);
   for(int i=0;i<n;i++)
     {
      x[i]=cx[i];
      y[i]=cy[i];
     }
   CApBuff buf;
//--- change x and y
   CBasicStatOps::RankX(x,n,buf);
   CBasicStatOps::RankX(y,n,buf);
//--- return result
   return(PearsonCorr2(x,y,n));
  }
//+------------------------------------------------------------------+
//| Covariance matrix                                                |
//| INPUT PARAMETERS:                                                |
//|     X   -   array[N,M], sample matrix:                           |
//|             * J-th column corresponds to J-th variable           |
//|             * I-th row corresponds to I-th observation           |
//|     N   -   N>=0, number of observations:                        |
//|             * if given, only leading N rows of X are used        |
//|             * if not given, automatically determined from input  |
//|               size                                               |
//|     M   -   M>0, number of variables:                            |
//|             * if given, only leading M columns of X are used     |
//|             * if not given, automatically determined from input  |
//|               size                                               |
//| OUTPUT PARAMETERS:                                               |
//|     C   -   array[M,M], covariance matrix (zero if N=0 or N=1)   |
//+------------------------------------------------------------------+
static bool CBaseStat::CovM(const CMatrixDouble &cx,const int n,const int m,
                            CMatrixDouble &c)
  {
//--- check
   if(!CAp::Assert(n>=0,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(m>=1,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Rows(cx)>=n,__FUNCTION__+": rows(x)<n"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Cols(cx)>=m || n==0,__FUNCTION__+": cols(x)<m"))
      return(false);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteMatrix(cx,n,m),__FUNCTION__+": x contains infinite/NAN elements"))
      return(false);
//--- create copy
   CMatrixDouble x;
   x=cx;
//--- N<=1, return zero
   if(n<=1)
     {
      c.Resize(m,m);
      for(int i=0;i<m;i++)
         for(int j=0;j<m;j++)
            c[i].Set(j,0);
      return(true);
     }
//--- create variables
   double v=1.0/(double)n;
   double t[];
   double x0[];
   bool   same[];
//--- Calculate means,
//--- check for constant columns
   ArrayResizeAL(t,m);
   ArrayResizeAL(x0,m);
   ArrayResizeAL(same,m);
   c.Resize(m,m);
//--- prepare arrays
   for(int i=0;i<m;i++)
     {
      t[i]=0;
      same[i]=true;
      x0[i]=x[0][i];
     }
//--- calculation
   for(int i=0;i<n;i++)
      for(int j=0;j<m;j++)
        {
         t[j]+=v*x[i][j];
         same[j]=same[j] && x[i][j]==x0[j];
        }
//--- * center variables;
//--- * if we have constant columns, these columns are
//---   artificially zeroed (they must be zero in exact arithmetics,
//---   but unfortunately floating point ops are not exact).
//--- * calculate upper half of symmetric covariance matrix
   for(int i=0;i<n;i++)
      for(int j=0;j<m;j++)
        {
         //--- check
         if(same[j]) x[i].Set(j,0);
         else        x[i].Set(j,x[i][j]-t[j]);
        }
//--- calculation
   CAblas::RMatrixSyrk(m,n,1.0/(double)(n-1),x,0,0,1,0.0,c,0,0,true);
//--- force symmetricity
   for(int i=0;i<m-1;i++)
      for(int j=i+1;j<m;j++)
         c[j].Set(i,c[i][j]);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Pearson product-moment correlation matrix                        |
//| INPUT PARAMETERS:                                                |
//|     X   -   array[N,M], sample matrix:                           |
//|             * J-th column corresponds to J-th variable           |
//|             * I-th row corresponds to I-th observation           |
//|     N   -   N>=0, number of observations:                        |
//|             * if given, only leading N rows of X are used        |
//|             * if not given, automatically determined from input  |
//|               size                                               |
//|     M   -   M>0, number of variables:                            |
//|             * if given, only leading M columns of X are used     |
//|             * if not given, automatically determined from input  |
//|               size                                               |
//| OUTPUT PARAMETERS:                                               |
//|     C   -   array[M,M], correlation matrix (zero if N=0 or N=1)  |
//+------------------------------------------------------------------+
static bool CBaseStat::PearsonCorrM(const CMatrixDouble &cx,const int n,
                                    const int m,CMatrixDouble &c)
  {
//--- check
   if(!CAp::Assert(n>=0,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(m>=1,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Rows(cx)>=n,__FUNCTION__+": rows(x)<n"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Cols(cx)>=m || n==0,__FUNCTION__+": cols(x)<m"))
      return(false);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteMatrix(cx,n,m),__FUNCTION__+": x contains infinite/NAN elements"))
      return(false);
//--- allocation
   c.Resize(m,m);
//--- calculation
   CovM(cx,n,m,c);
//--- create array
   double t[];
   ArrayResizeAL(t,m);
   for(int i=0;i<m;i++)
      t[i]=MathSqrt(c[i][i]);
//--- calculation
   for(int i=0;i<m;i++)
      for(int j=0;j<m;j++)
        {
         //--- check
         if(t[i]!=0 && t[j]!=0) c[i].Set(j,c[i][j]/(t[i]*t[j]));
         else                   c[i].Set(j,0);
        }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Spearman's rank correlation matrix                               |
//| INPUT PARAMETERS:                                                |
//|     X   -   array[N,M], sample matrix:                           |
//|             * J-th column corresponds to J-th variable           |
//|             * I-th row corresponds to I-th observation           |
//|     N   -   N>=0, number of observations:                        |
//|             * if given, only leading N rows of X are used        |
//|             * if not given, automatically determined from input  |
//|               size                                               |
//|     M   -   M>0, number of variables:                            |
//|             * if given, only leading M columns of X are used     |
//|             * if not given, automatically determined from input  |
//|               size                                               |
//| OUTPUT PARAMETERS:                                               |
//|     C   -   array[M,M], correlation matrix (zero if N=0 or N=1)  |
//+------------------------------------------------------------------+
static bool CBaseStat::SpearmanCorrM(const CMatrixDouble &cx,const int n,
                                     const int m,CMatrixDouble &c)
  {
//--- check
   if(!CAp::Assert(n>=0,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(m>=1,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Rows(cx)>=n,__FUNCTION__+": rows(x)<n"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Cols(cx)>=m || n==0,__FUNCTION__+": cols(x)<m"))
      return(false);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteMatrix(cx,n,m),__FUNCTION__+": x contains infinite/NAN elements"))
      return(false);
//--- create copy
   CMatrixDouble x;
   x=cx;
//--- N<=1, return zero
   if(n<=1)
     {
      c.Resize(m,m);
      for(int i=0;i<m;i++)
         for(int j=0;j<m;j++)
            c[i].Set(j,0);
      return(true);
     }
//--- create variables and arrays
   CApBuff buf;
   double  t[];
   double  v=1.0/(double)n;
   double  x0[];
   bool    same[];
//--- Allocate
   ArrayResizeAL(t,MathMax(n,m));
   ArrayResizeAL(x0,m);
   ArrayResizeAL(same,m);
   c.Resize(m,m);
//--- Replace data with ranks
   for(int j=0;j<m;j++)
     {
      for(int i=0;i<n;i++)
         t[i]=x[i][j];
      CBasicStatOps::RankX(t,n,buf);
      for(int i=0;i<n;i++)
         x[i].Set(j,t[i]);
     }
//--- prepare
   for(int i=0;i<m;i++)
     {
      t[i]=0;
      same[i]=true;
      x0[i]=x[0][i];
     }
//--- Calculate means,
//--- check for constant columns
   for(int i=0;i<n;i++)
      for(int j=0;j<m;j++)
        {
         t[j]+=v*x[i][j];
         same[j]=same[j] && x[i][j]==x0[j];
        }
//--- * center variables;
//--- * if we have constant columns, these columns are
//---   artificialy zeroed (they must be zero in exact arithmetics,
//---   but unfortunately floating point is not exact).
//--- * calculate upper half of symmetric covariance matrix
   for(int i=0;i<n;i++)
      for(int j=0;j<m;j++)
        {
         if(same[j]) x[i].Set(j,0);
         else        x[i].Set(j,x[i][j]-t[j]);
        }
//--- calculation
   CAblas::RMatrixSyrk(m,n,1.0/(double)(n-1),x,0,0,1,0.0,c,0,0,true);
//--- force symmetricity
   for(int i=0;i<m-1;i++)
      for(int j=i+1;j<m;j++)
         c[j].Set(i,c[i][j]);
//--- Calculate Pearson coefficients
   for(int i=0;i<m;i++)
      t[i]=MathSqrt(c[i][i]);
   for(int i=0;i<m;i++)
      for(int j=0;j<m;j++)
        {
         //--- check
         if(t[i]!=0 && t[j]!=0) c[i].Set(j,c[i][j]/(t[i]*t[j]));
         else                   c[i].Set(j,0);
        }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Cross-covariance matrix                                          |
//| INPUT PARAMETERS:                                                |
//|     X   -   array[N,M1], sample matrix:                          |
//|             * J-th column corresponds to J-th variable           |
//|             * I-th row corresponds to I-th observation           |
//|     Y   -   array[N,M2], sample matrix:                          |
//|             * J-th column corresponds to J-th variable           |
//|             * I-th row corresponds to I-th observation           |
//|     N   -   N>=0, number of observations:                        |
//|             * if given, only leading N rows of X/Y are used      |
//|             * if not given, automatically determined from input  |
//|               sizes                                              |
//|     M1  -   M1>0, number of variables in X:                      |
//|             * if given, only leading M1 columns of X are used    |
//|             * if not given, automatically determined from input  |
//|               size                                               |
//|     M2  -   M2>0, number of variables in Y:                      |
//|             * if given, only leading M1 columns of X are used    |
//|             * if not given, automatically determined from input  |
//|               size                                               |
//| OUTPUT PARAMETERS:                                               |
//|     C   -   array[M1,M2], cross-covariance matrix (zero if N=0 or|
//|             N=1)                                                 |
//+------------------------------------------------------------------+
static bool CBaseStat::CovM2(const CMatrixDouble &cx,const CMatrixDouble &cy,
                             const int n,const int m1,const int m2,
                             CMatrixDouble &c)
  {
//--- check
   if(!CAp::Assert(n>=0,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(m1>=1,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(m2>=1,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Rows(cx)>=n,__FUNCTION__+": rows(x)<n"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Cols(cx)>=m1 || n==0,__FUNCTION__+": cols(x)<m1"))
      return(false);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteMatrix(cx,n,m1),__FUNCTION__+": x contains infinite/NAN elements"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Rows(cy)>=n,__FUNCTION__+": rows(y)<n"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Cols(cy)>=m2 || n==0,__FUNCTION__+": cols(y)<m2"))
      return(false);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteMatrix(cy,n,m2),__FUNCTION__+": y contains infinite/NAN elements"))
      return(false);
//--- N<=1, return zero
   if(n<=1)
     {
      c.Resize(m1,m2);
      for(int i=0;i<m1;i++)
         for(int j=0;j<m2;j++)
            c[i].Set(j,0);
      return(true);
     }
//--- create copy
   CMatrixDouble x;
   CMatrixDouble y;
   x=cx;
   y=cy;
//--- create variables and arrays
   double v=1.0/(double)n;
   double t[];
   double x0[];
   double y0[];
   bool   samex[];
   bool   samey[];
//--- Allocate
   ArrayResizeAL(t,MathMax(m1,m2));
   ArrayResizeAL(x0,m1);
   ArrayResizeAL(y0,m2);
   ArrayResizeAL(samex,m1);
   ArrayResizeAL(samey,m2);
   c.Resize(m1,m2);
//--- * calculate means of X
//--- * center X
//--- * if we have constant columns, these columns are
//---   artificially zeroed (they must be zero in exact arithmetics,
//---   but unfortunately floating point ops are not exact).
   for(int i=0;i<m1;i++)
     {
      t[i]=0;
      samex[i]=true;
      x0[i]=x[0][i];
     }
   for(int i=0;i<n;i++)
      for(int j=0;j<m1;j++)
        {
         t[j]+=v*x[i][j];
         samex[j]=samex[j] && x[i][j]==x0[j];
        }
   for(int i=0;i<n;i++)
      for(int j=0;j<m1;j++)
        {
         //--- check
         if(samex[j]) x[i].Set(j,0);
         else         x[i].Set(j,x[i][j]-t[j]);
        }

//--- Repeat same steps for Y
   for(int i=0;i<m2;i++)
     {
      t[i]=0;
      samey[i]=true;
      y0[i]=y[0][i];
     }
   v=1.0/(double)n;
   for(int i=0;i<n;i++)
      for(int j=0;j<m2;j++)
        {
         t[j]+=v*y[i][j];
         samey[j]=samey[j] && y[i][j]==y0[j];
        }
   for(int i=0;i<n;i++)
     {
      for(int j=0;j<m2;j++)
        {
         //--- check
         if(samey[j]) y[i].Set(j,0);
         else         y[i].Set(j,y[i][j]-t[j]);
        }
     }
//--- calculate cross-covariance matrix
   CAblas::RMatrixGemm(m1,m2,n,1.0/(double)(n-1),x,0,0,1,y,0,0,0,0.0,c,0,0);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Pearson product-moment cross-correlation matrix                  |
//| INPUT PARAMETERS:                                                |
//|     X   -   array[N,M1], sample matrix:                          |
//|             * J-th column corresponds to J-th variable           |
//|             * I-th row corresponds to I-th observation           |
//|     Y   -   array[N,M2], sample matrix:                          |
//|             * J-th column corresponds to J-th variable           |
//|             * I-th row corresponds to I-th observation           |
//|     N   -   N>=0, number of observations:                        |
//|             * if given, only leading N rows of X/Y are used      |
//|             * if not given, automatically determined from input  |
//|               sizes                                              |
//|     M1  -   M1>0, number of variables in X:                      |
//|             * if given, only leading M1 columns of X are used    |
//|             * if not given, automatically determined from input  |
//|               size                                               |
//|     M2  -   M2>0, number of variables in Y:                      |
//|             * if given, only leading M1 columns of X are used    |
//|             * if not given, automatically determined from input  |
//|               size                                               |
//| OUTPUT PARAMETERS:                                               |
//|     C   -   array[M1,M2], cross-correlation matrix (zero if N=0  |
//|             or N=1)                                              |
//+------------------------------------------------------------------+
static bool CBaseStat::PearsonCorrM2(const CMatrixDouble &cx,const CMatrixDouble &cy,
                                     const int n,const int m1,const int m2,
                                     CMatrixDouble &c)
  {
//--- check
   if(!CAp::Assert(n>=0,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(m1>=1,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(m2>=1,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Rows(cx)>=n,__FUNCTION__+": rows(x)<n"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Cols(cx)>=m1 || n==0,__FUNCTION__+": cols(x)<m1"))
      return(false);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteMatrix(cx,n,m1),__FUNCTION__+": x contains infinite/NAN elements"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Rows(cy)>=n,__FUNCTION__+": rows(y)<n"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Cols(cy)>=m2 || n==0,__FUNCTION__+": cols(y)<m2"))
      return(false);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteMatrix(cy,n,m2),__FUNCTION__+": y contains infinite/NAN elements"))
      return(false);
//--- N<=1, return zero
   if(n<=1)
     {
      c.Resize(m1,m2);
      for(int i=0;i<m1;i++)
         for(int j=0;j<m2;j++)
            c[i].Set(j,0);
      return(true);
     }
//--- create copy
   CMatrixDouble x;
   CMatrixDouble y;
   x=cx;
   y=cy;
//--- create variables and arrays
   double v=1.0/(double)n;
   double t[];
   double x0[];
   double y0[];
   double sx[];
   double sy[];
   bool   samex[];
   bool   samey[];
//--- Allocate
   ArrayResizeAL(t,MathMax(m1,m2));
   ArrayResizeAL(x0,m1);
   ArrayResizeAL(y0,m2);
   ArrayResizeAL(sx,m1);
   ArrayResizeAL(sy,m2);
   ArrayResizeAL(samex,m1);
   ArrayResizeAL(samey,m2);
   c.Resize(m1,m2);
//--- * calculate means of X
//--- * center X
//--- * if we have constant columns, these columns are
//---   artificially zeroed (they must be zero in exact arithmetics,
//---   but unfortunately floating point ops are not exact).
//--- * calculate column variances
   for(int i=0;i<m1;i++)
     {
      t[i]=0;
      samex[i]=true;
      sx[i]=0;
      x0[i]=x[0][i];
     }
   for(int i=0;i<n;i++)
      for(int j=0;j<m1;j++)
        {
         t[j]+=v*x[i][j];
         samex[j]=samex[j] && x[i][j]==x0[j];
        }
   for(int i=0;i<n;i++)
     {
      for(int j=0;j<m1;j++)
        {
         //--- check
         if(samex[j]) x[i].Set(j,0);
         else         x[i].Set(j,x[i][j]-t[j]);
         //--- calculation
         sx[j]+=x[i][j]*x[i][j];
        }
     }
   for(int j=0;j<m1;j++)
      sx[j]=MathSqrt(sx[j]/(n-1));
//--- Repeat same steps for Y
   for(int i=0;i<m2;i++)
     {
      t[i]=0;
      samey[i]=true;
      sy[i]=0;
      y0[i]=y[0][i];
     }
   v=1.0/(double)n;
   for(int i=0;i<n;i++)
      for(int j=0;j<m2;j++)
        {
         t[j]+=v*y[i][j];
         samey[j]=samey[j] && y[i][j]==y0[j];
        }
   for(int i=0;i<n;i++)
      for(int j=0;j<m2;j++)
        {
         //--- check
         if(samey[j]) y[i].Set(j,0);
         else         y[i].Set(j,y[i][j]-t[j]);
         //--- calculation
         sy[j]+=y[i][j]*y[i][j];
        }
   for(int j=0;j<m2;j++)
      sy[j]=MathSqrt(sy[j]/(n-1));
//--- calculate cross-covariance matrix
   CAblas::RMatrixGemm(m1,m2,n,1.0/(double)(n-1),x,0,0,1,y,0,0,0,0.0,c,0,0);
//--- Divide by standard deviations
   for(int i=0;i<m1;i++)
      for(int j=0;j<m2;j++)
        {
         //--- check
         if(sx[i]!=0 && sy[j]!=0) c[i].Set(j,c[i][j]/(sx[i]*sy[j]));
         else                     c[i].Set(j,0);
        }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Spearman's rank cross-correlation matrix                         |
//| INPUT PARAMETERS:                                                |
//|     X   -   array[N,M1], sample matrix:                          |
//|             * J-th column corresponds to J-th variable           |
//|             * I-th row corresponds to I-th observation           |
//|     Y   -   array[N,M2], sample matrix:                          |
//|             * J-th column corresponds to J-th variable           |
//|             * I-th row corresponds to I-th observation           |
//|     N   -   N>=0, number of observations:                        |
//|             * if given, only leading N rows of X/Y are used      |
//|             * if not given, automatically determined from input  |
//|               sizes                                              |
//|     M1  -   M1>0, number of variables in X:                      |
//|             * if given, only leading M1 columns of X are used    |
//|             * if not given, automatically determined from input  |
//|               size                                               |
//|     M2  -   M2>0, number of variables in Y:                      |
//|             * if given, only leading M1 columns of X are used    |
//|             * if not given, automatically determined from input  |
//|               size                                               |
//| OUTPUT PARAMETERS:                                               |
//|     C   -   array[M1,M2], cross-correlation matrix (zero if N=0  |
//|             or N=1)                                              |
//+------------------------------------------------------------------+
static bool CBaseStat::SpearmanCorrM2(const CMatrixDouble &cx,const CMatrixDouble &cy,
                                      const int n,const int m1,const int m2,
                                      CMatrixDouble &c)
  {
//--- check
   if(!CAp::Assert(n>=0,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(m1>=1,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(m2>=1,__FUNCTION__+": the error variable"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Rows(cx)>=n,__FUNCTION__+": rows(x)<n"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Cols(cx)>=m1 || n==0,__FUNCTION__+": cols(x)<m1"))
      return(false);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteMatrix(cx,n,m1),__FUNCTION__+": x contains infinite/NAN elements"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Rows(cy)>=n,__FUNCTION__+": rows(y)<n"))
      return(false);
//--- check
   if(!CAp::Assert(CAp::Cols(cy)>=m2 || n==0,__FUNCTION__+": cols(y)<m2"))
      return(false);
//--- check
   if(!CAp::Assert(CApServ::IsFiniteMatrix(cy,n,m2),__FUNCTION__+": y contains infinite/NAN elements"))
      return(false);
//--- N<=1, return zero
   if(n<=1)
     {
      c.Resize(m1,m2);
      for(int i=0;i<m1;i++)
         for(int j=0;j<m2;j++)
            c[i].Set(j,0);
      return(true);
     }
//--- create copy
   CMatrixDouble x;
   CMatrixDouble y;
   x=cx;
   y=cy;
//--- create variables and arrays
   double  v=1.0/(double)n;
   double  t[];
   double  x0[];
   double  y0[];
   double  sx[];
   double  sy[];
   bool    samex[];
   bool    samey[];
   CApBuff buf;
//--- Allocate
   ArrayResizeAL(t,MathMax(MathMax(m1,m2),n));
   ArrayResizeAL(x0,m1);
   ArrayResizeAL(y0,m2);
   ArrayResizeAL(sx,m1);
   ArrayResizeAL(sy,m2);
   ArrayResizeAL(samex,m1);
   ArrayResizeAL(samey,m2);
   c.Resize(m1,m2);
//--- Replace data with ranks
   for(int j=0;j<m1;j++)
     {
      for(int i=0;i<n;i++)
         t[i]=x[i][j];
      //--- change
      CBasicStatOps::RankX(t,n,buf);
      for(int i=0;i<n;i++)
         x[i].Set(j,t[i]);
     }
   for(int j=0;j<m2;j++)
     {
      for(int i=0;i<n;i++)
         t[i]=y[i][j];
      //--- change
      CBasicStatOps::RankX(t,n,buf);
      for(int i=0;i<n;i++)
         y[i].Set(j,t[i]);
     }
//--- * calculate means of X
//--- * center X
//--- * if we have constant columns, these columns are
//---   artificially zeroed (they must be zero in exact arithmetics,
//---   but unfortunately floating point ops are not exact).
//--- * calculate column variances
   for(int i=0;i<m1;i++)
     {
      t[i]=0;
      samex[i]=true;
      sx[i]=0;
      x0[i]=x[0][i];
     }
   for(int i=0;i<n;i++)
      for(int j=0;j<m1;j++)
        {
         t[j]+=v*x[i][j];
         samex[j]=samex[j] && x[i][j]==x0[j];
        }
   for(int i=0;i<n;i++)
     {
      for(int j=0;j<m1;j++)
        {
         //--- check
         if(samex[j]) x[i].Set(j,0);
         else         x[i].Set(j,x[i][j]-t[j]);
         //--- calculation
         sx[j]+=x[i][j]*x[i][j];
        }
     }
   for(int j=0;j<m1;j++)
      sx[j]=MathSqrt(sx[j]/(n-1));
//--- Repeat same steps for Y
   for(int i=0;i<m2;i++)
     {
      t[i]=0;
      samey[i]=true;
      sy[i]=0;
      y0[i]=y[0][i];
     }
   v=1.0/(double)n;
   for(int i=0;i<n;i++)
      for(int j=0;j<m2;j++)
        {
         t[j]+=v*y[i][j];
         samey[j]=samey[j] && y[i][j]==y0[j];
        }
   for(int i=0;i<n;i++)
      for(int j=0;j<m2;j++)
        {
         //--- check
         if(samey[j]) y[i].Set(j,0);
         else         y[i].Set(j,y[i][j]-t[j]);
         //--- calculation
         sy[j]+=y[i][j]*y[i][j];
        }
   for(int j=0;j<m2;j++)
      sy[j]=MathSqrt(sy[j]/(n-1));
//--- calculate cross-covariance matrix
   CAblas::RMatrixGemm(m1,m2,n,1.0/(double)(n-1),x,0,0,1,y,0,0,0,0.0,c,0,0);
//--- Divide by standard deviations
   for(int i=0;i<m1;i++)
      for(int j=0;j<m2;j++)
        {
         //--- check
         if(sx[i]!=0 && sy[j]!=0) c[i].Set(j,c[i][j]/(sx[i]*sy[j]));
         else                     c[i].Set(j,0);
        }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Obsolete function, we recommend to use PearsonCorr2().           |
//+------------------------------------------------------------------+
static double CBaseStat::PearsonCorrelation(const double &x[],
                                            const double &y[],
                                            const int n)
  {
//--- return result
   return(PearsonCorr2(x,y,n));
  }
//+------------------------------------------------------------------+
//| Obsolete function, we recommend to use SpearmanCorr2().          |
//+------------------------------------------------------------------+
static double CBaseStat::SpearmanRankCorrelation(const double &x[],
                                                 const double &y[],
                                                 const int n)
  {
//--- return result
   return(SpearmanCorr2(x,y,n));
  }
//+------------------------------------------------------------------+
//| Correlation tests                                                |
//+------------------------------------------------------------------+
class CCorrTests
  {
private:
   //--- private methods
   static double     SpearmanTail5(const double s);
   static double     SpearmanTail6(const double s);
   static double     SpearmanTail7(const double s);
   static double     SpearmanTail8(const double s);
   static double     SpearmanTail9(const double s);
   static double     SpearmanTail(const double t,const int n);
public:
   //--- constructor, destructor
                     CCorrTests(void);
                    ~CCorrTests(void);
   //--- check hypothesis
   static void       PearsonCorrSignific(const double r,const int n,double &bothTails,double &leftTail,double &rightTail);
   static void       SpearmanRankCorrSignific(const double r,const int n,double &bothTails,double &leftTail,double &rightTail);
  };
//+------------------------------------------------------------------+
//| Constructor without parameters                                   |
//+------------------------------------------------------------------+
CCorrTests::CCorrTests(void)
  {

  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CCorrTests::~CCorrTests(void)
  {

  }
//+------------------------------------------------------------------+
//| Tail(T,N), accepts T<0                                           |
//+------------------------------------------------------------------+
static double CCorrTests::SpearmanTail(const double t,const int n)
  {
   if(!CAp::Assert(t<0,__FUNCTION__+": the error variable"))
      return(EMPTY_VALUE);
//--- check
   if(n==5)
      return(SpearmanTail5(-t));
//--- check
   if(n==6)
      return(SpearmanTail6(-t));
//--- check
   if(n==7)
      return(SpearmanTail7(-t));
//--- check
   if(n==8)
      return(SpearmanTail8(-t));
//--- check
   if(n==9)
      return(SpearmanTail9(-t));
//--- return result
   return(CStudenttDistr::StudenttDistribution(n-2,t));
  }
//+------------------------------------------------------------------+
//| Tail(S, 5)                                                       |
//+------------------------------------------------------------------+
static double CCorrTests::SpearmanTail5(const double s)
  {
//--- check
   if(s<0.000e+00)
      return(CStudenttDistr::StudenttDistribution(3,-s));
//--- check
   if(s>=3.580e+00)
      return(8.304e-03);
//--- check
   if(s>=2.322e+00)
      return(4.163e-02);
//--- check
   if(s>=1.704e+00)
      return(6.641e-02);
//--- check
   if(s>=1.303e+00)
      return(1.164e-01);
//--- check
   if(s>=1.003e+00)
      return(1.748e-01);
//--- check
   if(s>=7.584e-01)
      return(2.249e-01);
//--- check
   if(s>=5.468e-01)
      return(2.581e-01);
//--- check
   if(s>=3.555e-01)
      return(3.413e-01);
//--- check
   if(s>=1.759e-01)
      return(3.911e-01);
//--- check
   if(s>=1.741e-03)
      return(4.747e-01);
//--- check
   if(s>=0.000e+00)
      return(5.248e-01);
//--- return result
   return(0);
  }
//+------------------------------------------------------------------+
//| Tail(S, 6)                                                       |
//+------------------------------------------------------------------+
static double CCorrTests::SpearmanTail6(const double s)
  {
//--- check
   if(s<1.001e+00)
      return(CStudenttDistr::StudenttDistribution(4,-s));
//--- check 
   if(s>=5.663e+00)
      return(1.366e-03);
//--- check
   if(s>=3.834e+00)
      return(8.350e-03);
//--- check
   if(s>=2.968e+00)
      return(1.668e-02);
//--- check
   if(s>=2.430e+00)
      return(2.921e-02);
//--- check
   if(s>=2.045e+00)
      return(5.144e-02);
//--- check
   if(s>=1.747e+00)
      return(6.797e-02);
//--- check
   if(s>=1.502e+00)
      return(8.752e-02);
//--- check
   if(s>=1.295e+00)
      return(1.210e-01);
//--- check
   if(s>=1.113e+00)
      return(1.487e-01);
//--- check
   if(s>=1.001e+00)
      return(1.780e-01);
//--- return result
   return(0);
  }
//+------------------------------------------------------------------+
//| Tail(S, 7)                                                       |
//+------------------------------------------------------------------+
static double CCorrTests::SpearmanTail7(const double s)
  {
//--- check
   if(s<1.001e+00)
      return(CStudenttDistr::StudenttDistribution(5,-s));
//--- check
   if(s>=8.159e+00)
      return(2.081e-04);
//--- check
   if(s>=5.620e+00)
      return(1.393e-03);
//--- check
   if(s>=4.445e+00)
      return(3.398e-03);
//--- check
   if(s>=3.728e+00)
      return(6.187e-03);
//--- check
   if(s>=3.226e+00)
      return(1.200e-02);
//--- check
   if(s>=2.844e+00)
      return(1.712e-02);
//--- check
   if(s>=2.539e+00)
      return(2.408e-02);
//--- check
   if(s>=2.285e+00)
      return(3.320e-02);
//--- check
   if(s>=2.068e+00)
      return(4.406e-02);
//--- check
   if(s>=1.879e+00)
      return(5.478e-02);
//--- check
   if(s>=1.710e+00)
      return(6.946e-02);
//--- check
   if(s>=1.559e+00)
      return(8.331e-02);
//--- check
   if(s>=1.420e+00)
      return(1.001e-01);
//--- check
   if(s>=1.292e+00)
      return(1.180e-01);
//--- check
   if(s>=1.173e+00)
      return(1.335e-01);
//--- check
   if(s>=1.062e+00)
      return(1.513e-01);
//--- check
   if(s>=1.001e+00)
      return(1.770e-01);
//--- return result
   return(0);
  }
//+------------------------------------------------------------------+
//| Tail(S, 8)                                                       |
//+------------------------------------------------------------------+
static double CCorrTests::SpearmanTail8(const double s)
  {
//--- check
   if(s<2.001e+00)
      return(CStudenttDistr::StudenttDistribution(6,-s));
//--- check
   if(s>=1.103e+01)
      return(2.194e-05);
//--- check
   if(s>=7.685e+00)
      return(2.008e-04);
//--- check
   if(s>=6.143e+00)
      return(5.686e-04);
//--- check
   if(s>=5.213e+00)
      return(1.138e-03);
//--- check
   if(s>=4.567e+00)
      return(2.310e-03);
//--- check
   if(s>=4.081e+00)
      return(3.634e-03);
//--- check
   if(s>=3.697e+00)
      return(5.369e-03);
//--- check
   if(s>=3.381e+00)
      return(7.708e-03);
//--- check
   if(s>=3.114e+00)
      return(1.087e-02);
//--- check
   if(s>=2.884e+00)
      return(1.397e-02);
//--- check
   if(s>=2.682e+00)
      return(1.838e-02);
//--- check
   if(s>=2.502e+00)
      return(2.288e-02);
//--- check
   if(s>=2.340e+00)
      return(2.883e-02);
//--- check
   if(s>=2.192e+00)
      return(3.469e-02);
//--- check
   if(s>=2.057e+00)
      return(4.144e-02);
//--- check
   if(s>=2.001e+00)
      return(4.804e-02);
//--- return result
   return(0);
  }
//+------------------------------------------------------------------+
//| Tail(S, 9)                                                       |
//+------------------------------------------------------------------+
static double CCorrTests::SpearmanTail9(const double s)
  {
//--- check
   if(s<2.001e+00)
      return(CStudenttDistr::StudenttDistribution(7,-s));
//--- check
   if(s>=9.989e+00)
      return(2.306e-05);
//--- check
   if(s>=8.069e+00)
      return(8.167e-05);
//--- check
   if(s>=6.890e+00)
      return(1.744e-04);
//--- check
   if(s>=6.077e+00)
      return(3.625e-04);
//--- check
   if(s>=5.469e+00)
      return(6.450e-04);
//--- check
   if(s>=4.991e+00)
      return(1.001e-03);
//--- check
   if(s>=4.600e+00)
      return(1.514e-03);
//--- check
   if(s>=4.272e+00)
      return(2.213e-03);
//--- check
   if(s>=3.991e+00)
      return(2.990e-03);
//--- check
   if(s>=3.746e+00)
      return(4.101e-03);
//--- check
   if(s>=3.530e+00)
      return(5.355e-03);
//--- check
   if(s>=3.336e+00)
      return(6.887e-03);
//--- check
   if(s>=3.161e+00)
      return(8.598e-03);
//--- check
   if(s>=3.002e+00)
      return(1.065e-02);
//--- check
   if(s>=2.855e+00)
      return(1.268e-02);
//--- check
   if(s>=2.720e+00)
      return(1.552e-02);
//--- check
   if(s>=2.595e+00)
      return(1.836e-02);
//--- check
   if(s>=2.477e+00)
      return(2.158e-02);
//--- check
   if(s>=2.368e+00)
      return(2.512e-02);
//--- check
   if(s>=2.264e+00)
      return(2.942e-02);
//--- check
   if(s>=2.166e+00)
      return(3.325e-02);
//--- check
   if(s>=2.073e+00)
      return(3.800e-02);
//--- check
   if(s>=2.001e+00)
      return(4.285e-02);
//--- return result
   return(0);
  }
//+------------------------------------------------------------------+
//| Pearson's correlation coefficient significance test              |
//| This test checks hypotheses about whether X  and Y are samples of|
//| two continuous distributions having zero correlation or whether  |
//| their correlation is non-zero.                                   |
//| The following tests are performed:                               |
//|     * two-tailed test (null hypothesis - X and Y have zero       |
//|       correlation)                                               |
//|     * left-tailed test (null hypothesis - the correlation        |
//|       coefficient is greater than or equal to 0)                 |
//|     * right-tailed test (null hypothesis - the correlation       |
//|       coefficient is less than or equal to 0).                   |
//| Requirements:                                                    |
//|     * the number of elements in each sample is not less than 5   |
//|     * normality of distributions of X and Y.                     |
//| Input parameters:                                                |
//|     R   -   Pearson's correlation coefficient for X and Y        |
//|     N   -   number of elements in samples, N>=5.                 |
//| Output parameters:                                               |
//|     BothTails   -   p-value for two-tailed test.                 |
//|                     If BothTails is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//|     LeftTail    -   p-value for left-tailed test.                |
//|                     If LeftTail is less than the given           |
//|                     significance level, the null hypothesis is   |
//|                     rejected.                                    |
//|     RightTail   -   p-value for right-tailed test.               |
//|                     If RightTail is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//+------------------------------------------------------------------+
static void CCorrTests::PearsonCorrSignific(const double r,const int n,
                                            double &bothTails,double &leftTail,
                                            double &rightTail)
  {
//--- Some special cases
   if(r>=1)
     {
      bothTails=0.0;
      leftTail=1.0;
      rightTail=0.0;
      return;
     }
//--- check
   if(r<=-1)
     {
      bothTails=0.0;
      leftTail=0.0;
      rightTail=1.0;
      return;
     }
//--- check
   if(n<5)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      return;
     }
//--- create variables
   double t;
   double p;
//--- calculation
   t=r*MathSqrt((n-2)/(1-CMath::Sqr(r)));
   p=CStudenttDistr::StudenttDistribution(n-2,t);
   bothTails=2*MathMin(p,1-p);
   leftTail=p;
   rightTail=1-p;
  }
//+------------------------------------------------------------------+
//| Spearman's rank correlation coefficient significance test        |
//| This test checks hypotheses about whether X and Y are samples of |
//| two continuous distributions having zero correlation or whether  |
//| their correlation is non-zero.                                   |
//| The following tests are performed:                               |
//|     * two-tailed test (null hypothesis - X and Y have zero       |
//|       correlation)                                               |
//|     * left-tailed test (null hypothesis - the correlation        |
//|       coefficient is greater than or equal to 0)                 |
//|     * right-tailed test (null hypothesis - the correlation       |
//|       coefficient is less than or equal to 0).                   |
//| Requirements:                                                    |
//|     * the number of elements in each sample is not less than 5.  |
//| The test is non-parametric and doesn't require distributions X   |
//| and Y to be normal.                                              |
//| Input parameters:                                                |
//|     R   -   Spearman's rank correlation coefficient for X and Y  |
//|     N   -   number of elements in samples, N>=5.                 |
//| Output parameters:                                               |
//|     BothTails   -   p-value for two-tailed test.                 |
//|                     If BothTails is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//|     LeftTail    -   p-value for left-tailed test.                |
//|                     If LeftTail is less than the given           |
//|                     significance level, the null hypothesis is   |
//|                     rejected.                                    |
//|     RightTail   -   p-value for right-tailed test.               |
//|                     If RightTail is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//+------------------------------------------------------------------+
static void CCorrTests::SpearmanRankCorrSignific(const double r,const int n,
                                                 double &bothTails,double &leftTail,
                                                 double &rightTail)
  {
//--- Special case
   if(n<5)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      return;
     }
//--- create variables
   double t;
   double p;
//--- General case
   if(r>=1)
      t=1.0E10;
   else
     {
      //--- check
      if(r<=-1)
         t=-1.0E10;
      else
         t=r*MathSqrt((n-2)/(1-CMath::Sqr(r)));
     }
//--- check
   if(t<0)
     {
      p=SpearmanTail(t,n);
      bothTails=2*p;
      leftTail=p;
      rightTail=1-p;
     }
   else
     {
      p=SpearmanTail(-t,n);
      bothTails=2*p;
      leftTail=1-p;
      rightTail=p;
     }
  }
//+------------------------------------------------------------------+
//| Jarque-Bera test                                                 |
//+------------------------------------------------------------------+
class CJarqueBera
  {
private:
   static bool       JarqueBeraStat(const double &x[],const int n,double &s);
   static double     JarqueBeraApprox(const int n,const double s);
   static void       JBCheb(double x,double c,double &tj,double &tj1,double &r);
   static double     JBTbl5(const double s);
   static double     JBTbl6(const double s);
   static double     JBTbl7(const double s);
   static double     JBTbl8(const double s);
   static double     JBTbl9(const double s);
   static double     JBTbl10(const double s);
   static double     JBTbl11(const double s);
   static double     JBTbl12(const double s);
   static double     JBTbl13(const double s);
   static double     JBTbl14(const double s);
   static double     JBTbl15(const double s);
   static double     JBTbl16(const double s);
   static double     JBTbl17(const double s);
   static double     JBTbl18(const double s);
   static double     JBTbl19(const double s);
   static double     JBTbl20(const double s);
   static double     JBTbl30(const double s);
   static double     JBTbl50(const double s);
   static double     JBTbl65(const double s);
   static double     JBTbl100(const double s);
   static double     JBTbl130(const double s);
   static double     JBTbl200(const double s);
   static double     JBTbl301(const double s);
   static double     JBTbl501(const double s);
   static double     JBTbl701(const double s);
   static double     JBTbl1401(const double s);
public:
   //--- constructor, destructor
                     CJarqueBera(void);
                    ~CJarqueBera(void);
   //--- method
   static bool       JarqueBeraTest(const double &x[],const int n,double &p);
  };
//+------------------------------------------------------------------+
//| Constructor without parameters                                   |
//+------------------------------------------------------------------+
CJarqueBera::CJarqueBera(void)
  {

  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CJarqueBera::~CJarqueBera(void)
  {

  }
//+------------------------------------------------------------------+
//| Jarque-Bera test                                                 |
//| This test checks hypotheses about the fact that a given sample X |
//| is a sample of normal random variable.                           |
//| Requirements:                                                    |
//|     * the number of elements in the sample is not less than 5.   |
//| Input parameters:                                                |
//|     X   -   sample. Array whose index goes from 0 to N-1.        |
//|     N   -   size of the sample. N>=5                             |
//| Output parameters:                                               |
//|     BothTails   -   p-value for two-tailed test.                 |
//|                     If BothTails is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//|     LeftTail    -   p-value for left-tailed test.                |
//|                     If LeftTail is less than the given           |
//|                     significance level, the null hypothesis is   |
//|                     rejected.                                    |
//|     RightTail   -   p-value for right-tailed test.               |
//|                     If RightTail is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//| Accuracy of the approximation used (5<=N<=1951):                 |
//| p-value  	    relative error (5<=N<=1951)                       |
//| [1, 0.1]            < 1%                                         |
//| [0.1, 0.01]         < 2%                                         |
//| [0.01, 0.001]       < 6%                                         |
//| [0.001, 0]          wasn't measured                              |
//| For N>1951 accuracy wasn't measured but it shouldn't be sharply  |
//| different from table values.                                     |
//+------------------------------------------------------------------+
static bool CJarqueBera::JarqueBeraTest(const double &x[],const int n,
                                        double &p)
  {
//--- create a variable
   double s;
//--- N is too small
   if(n<5)
     {
      p=1.0;
      return(true);
     }
//--- N is large enough
   if(!JarqueBeraStat(x,n,s))
      return(false);
   p=JarqueBeraApprox(n,s);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Jarque-Bera statistics                                           |
//+------------------------------------------------------------------+
static bool CJarqueBera::JarqueBeraStat(const double &x[],const int n,
                                        double &s)
  {
//--- check
   if(!CAp::Assert(n>1,__FUNCTION__+": the error variable"))
      return(false);
//--- create variables
   int    i=0;
   double v=0;
   double v1=0;
   double v2=0;
   double stddev=0;
   double mean=0;
   double variance=0;
   double skewness=0;
   double kurtosis=0;
//--- Mean
   for(i=0;i<n;i++)
      mean+=x[i];
   mean/=n;
//--- Variance (using corrected two-pass algorithm)
   if(n!=1)
     {
      v1=0;
      for(i=0;i<n;i++)
        {
         v1+=CMath::Sqr(x[i]-mean);
         v2+=x[i]-mean;
        }
      v2=CMath::Sqr(v2)/n;
      variance=(v1-v2)/(n-1);
      //--- check
      if(variance<0)
         variance=0;
      stddev=MathSqrt(variance);
     }
//--- check
   if(stddev!=0)
     {
      //--- Skewness and kurtosis
      for(i=0;i<n;i++)
        {
         v=(x[i]-mean)/stddev;
         v2=CMath::Sqr(v);
         skewness+=v2*v;
         kurtosis+=CMath::Sqr(v2);
        }
      //--- change values
      skewness=skewness/n;
      kurtosis=kurtosis/n-3;
      //--- Statistic
      s=(double)n/(double)6*(CMath::Sqr(skewness)+CMath::Sqr(kurtosis)/4);
     }
   else
      return(false);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Internal subroutine                                              |
//+------------------------------------------------------------------+
static double CJarqueBera::JarqueBeraApprox(const int n,const double s)
  {
//--- create variables
   double result;
   double t1;
   double t2;
   double t3;
   double t;
   double f1;
   double f2;
   double f3;
   double f12;
   double f23;
   double x=s;
//--- check
   if(n<5)
      return(1);
//--- N = 5..20 are tabulated
   if(n>=5 && n<=20)
     {
      //--- check
      if(n==5)
         return(MathExp(JBTbl5(x)));
      //--- check
      if(n==6)
         return(MathExp(JBTbl6(x)));
      //--- check
      if(n==7)
         return(MathExp(JBTbl7(x)));
      //--- check
      if(n==8)
         return(MathExp(JBTbl8(x)));
      //--- check
      if(n==9)
         return(MathExp(JBTbl9(x)));
      //--- check
      if(n==10)
         return(MathExp(JBTbl10(x)));
      //--- check
      if(n==11)
         return(MathExp(JBTbl11(x)));
      //--- check
      if(n==12)
         return(MathExp(JBTbl12(x)));
      //--- check
      if(n==13)
         return(MathExp(JBTbl13(x)));
      //--- check
      if(n==14)
         return(MathExp(JBTbl14(x)));
      //--- check
      if(n==15)
         return(MathExp(JBTbl15(x)));
      //--- check
      if(n==16)
         return(MathExp(JBTbl16(x)));
      //--- check
      if(n==17)
         return(MathExp(JBTbl17(x)));
      //--- check
      if(n==18)
         return(MathExp(JBTbl18(x)));
      //--- check
      if(n==19)
         return(MathExp(JBTbl19(x)));
      //--- check
      if(n==20)
         return(MathExp(JBTbl20(x)));
     }
//--- N = 20, 30, 50 are tabulated.
//--- In-between values are interpolated
//--- using interpolating polynomial of the second degree.
   if(n>20 && n<=50)
     {
      t1=-1.0/20.0;
      t2=-1.0/30.0;
      t3=-1.0/50.0;
      t=-1.0/n;
      //--- tabulation
      f1=JBTbl20(x);
      f2=JBTbl30(x);
      f3=JBTbl50(x);
      //--- interpolating
      f12=((t-t2)*f1+(t1-t)*f2)/(t1-t2);
      f23=((t-t3)*f2+(t2-t)*f3)/(t2-t3);
      result=((t-t3)*f12+(t1-t)*f23)/(t1-t3);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(MathExp(result));
     }
//--- N = 50, 65, 100 are tabulated.
//--- In-between values are interpolated
//--- using interpolating polynomial of the second degree.
   if(n>50 && n<=100)
     {
      t1=-1.0/50.0;
      t2=-1.0/65.0;
      t3=-1.0/100.0;
      t=-1.0/n;
      //--- tabulation
      f1=JBTbl50(x);
      f2=JBTbl65(x);
      f3=JBTbl100(x);
      //--- interpolating
      f12=((t-t2)*f1+(t1-t)*f2)/(t1-t2);
      f23=((t-t3)*f2+(t2-t)*f3)/(t2-t3);
      result=((t-t3)*f12+(t1-t)*f23)/(t1-t3);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(MathExp(result));
     }
//--- N = 100, 130, 200 are tabulated.
//--- In-between values are interpolated
//--- using interpolating polynomial of the second degree.
   if(n>100 && n<=200)
     {
      t1=-(1.0/100.0);
      t2=-(1.0/130.0);
      t3=-(1.0/200.0);
      t=-(1.0/n);
      //--- tabulation
      f1=JBTbl100(x);
      f2=JBTbl130(x);
      f3=JBTbl200(x);
      //--- interpolating
      f12=((t-t2)*f1+(t1-t)*f2)/(t1-t2);
      f23=((t-t3)*f2+(t2-t)*f3)/(t2-t3);
      result=((t-t3)*f12+(t1-t)*f23)/(t1-t3);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(MathExp(result));
     }
//--- N = 200, 301, 501 are tabulated.
//--- In-between values are interpolated
//--- using interpolating polynomial of the second degree.
   if(n>200 && n<=501)
     {
      t1=-(1.0/200.0);
      t2=-(1.0/301.0);
      t3=-(1.0/501.0);
      t=-(1.0/n);
      //--- tabulation
      f1=JBTbl200(x);
      f2=JBTbl301(x);
      f3=JBTbl501(x);
      //--- interpolating
      f12=((t-t2)*f1+(t1-t)*f2)/(t1-t2);
      f23=((t-t3)*f2+(t2-t)*f3)/(t2-t3);
      result=((t-t3)*f12+(t1-t)*f23)/(t1-t3);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(MathExp(result));
     }
//--- N = 501, 701, 1401 are tabulated.
//--- In-between values are interpolated
//--- using interpolating polynomial of the second degree.
   if(n>501 && n<=1401)
     {
      t1=-(1.0/501.0);
      t2=-(1.0/701.0);
      t3=-(1.0/1401.0);
      t=-(1.0/n);
      //--- tabulation
      f1=JBTbl501(x);
      f2=JBTbl701(x);
      f3=JBTbl1401(x);
      //--- interpolating
      f12=((t-t2)*f1+(t1-t)*f2)/(t1-t2);
      f23=((t-t3)*f2+(t2-t)*f3)/(t2-t3);
      result=((t-t3)*f12+(t1-t)*f23)/(t1-t3);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(MathExp(result));
     }
//--- get result
   result=-(0.5*x)+(JBTbl1401(x)+0.5*x)*MathSqrt((double)1401/(double)n);
//--- check
   if(result>0)
      result=0;
//--- return result
   return(MathExp(result));
  }
//+------------------------------------------------------------------+
//| Internal subroutine                                              |
//+------------------------------------------------------------------+
static void CJarqueBera::JBCheb(double x,double c,double &tj,double &tj1,
                                double &r)
  {
//--- create variables
   double t;
//--- change values
   r+=c*tj;
   t=2*x*tj1-tj;
   tj=tj1;
   tj1=t;
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 5                         |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl5(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=0.4000)
     {
      x=2*s/0.400000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.097885e-20,tj,tj1,result);
      JBCheb(x,-2.854501e-20,tj,tj1,result);
      JBCheb(x,-1.756616e-20,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=1.1000)
     {
      x=2*(s-0.400000)/0.700000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.324545e+00,tj,tj1,result);
      JBCheb(x,-1.075941e+00,tj,tj1,result);
      JBCheb(x,-9.772272e-01,tj,tj1,result);
      JBCheb(x,3.175686e-01,tj,tj1,result);
      JBCheb(x,-1.576162e-01,tj,tj1,result);
      JBCheb(x,1.126861e-01,tj,tj1,result);
      JBCheb(x,-3.434425e-02,tj,tj1,result);
      JBCheb(x,-2.790359e-01,tj,tj1,result);
      JBCheb(x,2.809178e-02,tj,tj1,result);
      JBCheb(x,-5.479704e-01,tj,tj1,result);
      JBCheb(x,3.717040e-02,tj,tj1,result);
      JBCheb(x,-5.294170e-01,tj,tj1,result);
      JBCheb(x,2.880632e-02,tj,tj1,result);
      JBCheb(x,-3.023344e-01,tj,tj1,result);
      JBCheb(x,1.601531e-02,tj,tj1,result);
      JBCheb(x,-7.920403e-02,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(5.188419e+02*(s-1.100000e+00))-4.767297e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 6                         |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl6(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=0.2500)
     {
      x=2*(s-0.000000)/0.250000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-2.274707e-04,tj,tj1,result);
      JBCheb(x,-5.700471e-04,tj,tj1,result);
      JBCheb(x,-3.425764e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=1.3000)
     {
      x=2*(s-0.250000)/1.050000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.339000e+00,tj,tj1,result);
      JBCheb(x,-2.011104e+00,tj,tj1,result);
      JBCheb(x,-8.168177e-01,tj,tj1,result);
      JBCheb(x,-1.085666e-01,tj,tj1,result);
      JBCheb(x,7.738606e-02,tj,tj1,result);
      JBCheb(x,7.022876e-02,tj,tj1,result);
      JBCheb(x,3.462402e-02,tj,tj1,result);
      JBCheb(x,6.908270e-03,tj,tj1,result);
      JBCheb(x,-8.230772e-03,tj,tj1,result);
      JBCheb(x,-1.006996e-02,tj,tj1,result);
      JBCheb(x,-5.410222e-03,tj,tj1,result);
      JBCheb(x,-2.893768e-03,tj,tj1,result);
      JBCheb(x,8.114564e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=1.8500)
     {
      x=2*(s-1.300000)/0.550000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-6.794311e+00,tj,tj1,result);
      JBCheb(x,-3.578700e+00,tj,tj1,result);
      JBCheb(x,-1.394664e+00,tj,tj1,result);
      JBCheb(x,-7.928290e-01,tj,tj1,result);
      JBCheb(x,-4.813273e-01,tj,tj1,result);
      JBCheb(x,-3.076063e-01,tj,tj1,result);
      JBCheb(x,-1.835380e-01,tj,tj1,result);
      JBCheb(x,-1.013013e-01,tj,tj1,result);
      JBCheb(x,-5.058903e-02,tj,tj1,result);
      JBCheb(x,-1.856915e-02,tj,tj1,result);
      JBCheb(x,-6.710887e-03,tj,tj1,result);
      //---
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(1.770029e+02*(s-1.850000e+00))-1.371015e+01;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 7                         |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl7(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=1.4000)
     {
      x=2*(s-0.000000)/1.400000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.093681e+00,tj,tj1,result);
      JBCheb(x,-1.695911e+00,tj,tj1,result);
      JBCheb(x,-7.473192e-01,tj,tj1,result);
      JBCheb(x,-1.203236e-01,tj,tj1,result);
      JBCheb(x,6.590379e-02,tj,tj1,result);
      JBCheb(x,6.291876e-02,tj,tj1,result);
      JBCheb(x,3.132007e-02,tj,tj1,result);
      JBCheb(x,9.411147e-03,tj,tj1,result);
      JBCheb(x,-1.180067e-03,tj,tj1,result);
      JBCheb(x,-3.487610e-03,tj,tj1,result);
      JBCheb(x,-2.436561e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=3.0000)
     {
      x=2*(s-1.400000)/1.600000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-5.947854e+00,tj,tj1,result);
      JBCheb(x,-2.772675e+00,tj,tj1,result);
      JBCheb(x,-4.707912e-01,tj,tj1,result);
      JBCheb(x,-1.691171e-01,tj,tj1,result);
      JBCheb(x,-4.132795e-02,tj,tj1,result);
      JBCheb(x,-1.481310e-02,tj,tj1,result);
      JBCheb(x,2.867536e-03,tj,tj1,result);
      JBCheb(x,8.772327e-04,tj,tj1,result);
      JBCheb(x,5.033387e-03,tj,tj1,result);
      JBCheb(x,-1.378277e-03,tj,tj1,result);
      JBCheb(x,-2.497964e-03,tj,tj1,result);
      JBCheb(x,-3.636814e-03,tj,tj1,result);
      JBCheb(x,-9.581640e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=3.2000)
     {
      x=2*(s-3.000000)/0.200000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-7.511008e+00,tj,tj1,result);
      JBCheb(x,-8.140472e-01,tj,tj1,result);
      JBCheb(x,1.682053e+00,tj,tj1,result);
      JBCheb(x,-2.568561e-02,tj,tj1,result);
      JBCheb(x,-1.933930e+00,tj,tj1,result);
      JBCheb(x,-8.140472e-01,tj,tj1,result);
      JBCheb(x,-3.895025e+00,tj,tj1,result);
      JBCheb(x,-8.140472e-01,tj,tj1,result);
      JBCheb(x,-1.933930e+00,tj,tj1,result);
      JBCheb(x,-2.568561e-02,tj,tj1,result);
      JBCheb(x,1.682053e+00,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(1.824116e+03*(s-3.200000e+00))-1.440330e+01;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 8                         |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl8(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=1.3000)
     {
      x=2*(s-0.000000)/1.300000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-7.199015e-01,tj,tj1,result);
      JBCheb(x,-1.095921e+00,tj,tj1,result);
      JBCheb(x,-4.736828e-01,tj,tj1,result);
      JBCheb(x,-1.047438e-01,tj,tj1,result);
      JBCheb(x,-2.484320e-03,tj,tj1,result);
      JBCheb(x,7.937923e-03,tj,tj1,result);
      JBCheb(x,4.810470e-03,tj,tj1,result);
      JBCheb(x,2.139780e-03,tj,tj1,result);
      JBCheb(x,6.708443e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=2.0000)
     {
      x=2*(s-1.300000)/0.700000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-3.378966e+00,tj,tj1,result);
      JBCheb(x,-7.802461e-01,tj,tj1,result);
      JBCheb(x,1.547593e-01,tj,tj1,result);
      JBCheb(x,-6.241042e-02,tj,tj1,result);
      JBCheb(x,1.203274e-02,tj,tj1,result);
      JBCheb(x,5.201990e-03,tj,tj1,result);
      JBCheb(x,-5.125597e-03,tj,tj1,result);
      JBCheb(x,1.584426e-03,tj,tj1,result);
      JBCheb(x,2.546069e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=5.0000)
     {
      x=2*(s-2.000000)/3.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-6.828366e+00,tj,tj1,result);
      JBCheb(x,-3.137533e+00,tj,tj1,result);
      JBCheb(x,-5.016671e-01,tj,tj1,result);
      JBCheb(x,-1.745637e-01,tj,tj1,result);
      JBCheb(x,-5.189801e-02,tj,tj1,result);
      JBCheb(x,-1.621610e-02,tj,tj1,result);
      JBCheb(x,-6.741122e-03,tj,tj1,result);
      JBCheb(x,-4.516368e-03,tj,tj1,result);
      JBCheb(x,3.552085e-04,tj,tj1,result);
      JBCheb(x,2.787029e-03,tj,tj1,result);
      JBCheb(x,5.359774e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(5.087028e+00*(s-5.000000e+00))-1.071300e+01;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 9                         |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl9(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=1.3000)
     {
      x=2*(s-0.000000)/1.300000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-6.279320e-01,tj,tj1,result);
      JBCheb(x,-9.277151e-01,tj,tj1,result);
      JBCheb(x,-3.669339e-01,tj,tj1,result);
      JBCheb(x,-7.086149e-02,tj,tj1,result);
      JBCheb(x,-1.333816e-03,tj,tj1,result);
      JBCheb(x,3.871249e-03,tj,tj1,result);
      JBCheb(x,2.007048e-03,tj,tj1,result);
      JBCheb(x,7.482245e-04,tj,tj1,result);
      JBCheb(x,2.355615e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=2.0000)
     {
      x=2*(s-1.300000)/0.700000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-2.981430e+00,tj,tj1,result);
      JBCheb(x,-7.972248e-01,tj,tj1,result);
      JBCheb(x,1.747737e-01,tj,tj1,result);
      JBCheb(x,-3.808530e-02,tj,tj1,result);
      JBCheb(x,-7.888305e-03,tj,tj1,result);
      JBCheb(x,9.001302e-03,tj,tj1,result);
      JBCheb(x,-1.378767e-03,tj,tj1,result);
      JBCheb(x,-1.108510e-03,tj,tj1,result);
      JBCheb(x,5.915372e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=7.0000)
     {
      x=2*(s-2.000000)/5.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-6.387463e+00,tj,tj1,result);
      JBCheb(x,-2.845231e+00,tj,tj1,result);
      JBCheb(x,-1.809956e-01,tj,tj1,result);
      JBCheb(x,-7.543461e-02,tj,tj1,result);
      JBCheb(x,-4.880397e-03,tj,tj1,result);
      JBCheb(x,-1.160074e-02,tj,tj1,result);
      JBCheb(x,-7.356527e-03,tj,tj1,result);
      JBCheb(x,-4.394428e-03,tj,tj1,result);
      JBCheb(x,9.619892e-04,tj,tj1,result);
      JBCheb(x,-2.758763e-04,tj,tj1,result);
      JBCheb(x,4.790977e-05,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(2.020952e+00*(s-7.000000e+00))-9.516623e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 10                        |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl10(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=1.2000)
     {
      x=2*(s-0.000000)/1.200000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-4.590993e-01,tj,tj1,result);
      JBCheb(x,-6.562730e-01,tj,tj1,result);
      JBCheb(x,-2.353934e-01,tj,tj1,result);
      JBCheb(x,-4.069933e-02,tj,tj1,result);
      JBCheb(x,-1.849151e-03,tj,tj1,result);
      JBCheb(x,8.931406e-04,tj,tj1,result);
      JBCheb(x,3.636295e-04,tj,tj1,result);
      JBCheb(x,1.178340e-05,tj,tj1,result);
      JBCheb(x,-8.917749e-05,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=2.0000)
     {
      x=2*(s-1.200000)/0.800000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-2.537658e+00,tj,tj1,result);
      JBCheb(x,-9.962401e-01,tj,tj1,result);
      JBCheb(x,1.838715e-01,tj,tj1,result);
      JBCheb(x,1.055792e-02,tj,tj1,result);
      JBCheb(x,-2.580316e-02,tj,tj1,result);
      JBCheb(x,1.781701e-03,tj,tj1,result);
      JBCheb(x,3.770362e-03,tj,tj1,result);
      JBCheb(x,-4.838983e-04,tj,tj1,result);
      JBCheb(x,-6.999052e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=7.0000)
     {
      x=2*(s-2.000000)/5.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-5.337524e+00,tj,tj1,result);
      JBCheb(x,-1.877029e+00,tj,tj1,result);
      JBCheb(x,4.734650e-02,tj,tj1,result);
      JBCheb(x,-4.249254e-02,tj,tj1,result);
      JBCheb(x,3.320250e-03,tj,tj1,result);
      JBCheb(x,-6.432266e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(8.711035e-01*(s-7.000000e+00))-7.212811e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 11                        |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl11(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=1.2000)
     {
      x=2*(s-0.000000)/1.200000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-4.339517e-01,tj,tj1,result);
      JBCheb(x,-6.051558e-01,tj,tj1,result);
      JBCheb(x,-2.000992e-01,tj,tj1,result);
      JBCheb(x,-3.022547e-02,tj,tj1,result);
      JBCheb(x,-9.808401e-04,tj,tj1,result);
      JBCheb(x,5.592870e-04,tj,tj1,result);
      JBCheb(x,3.575081e-04,tj,tj1,result);
      JBCheb(x,2.086173e-04,tj,tj1,result);
      JBCheb(x,6.089011e-05,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=2.2500)
     {
      x=2*(s-1.200000)/1.050000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-2.523221e+00,tj,tj1,result);
      JBCheb(x,-1.068388e+00,tj,tj1,result);
      JBCheb(x,2.179661e-01,tj,tj1,result);
      JBCheb(x,-1.555524e-03,tj,tj1,result);
      JBCheb(x,-3.238964e-02,tj,tj1,result);
      JBCheb(x,7.364320e-03,tj,tj1,result);
      JBCheb(x,4.895771e-03,tj,tj1,result);
      JBCheb(x,-1.762774e-03,tj,tj1,result);
      JBCheb(x,-8.201340e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=8.0000)
     {
      x=2*(s-2.250000)/5.750000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-5.212179e+00,tj,tj1,result);
      JBCheb(x,-1.684579e+00,tj,tj1,result);
      JBCheb(x,8.299519e-02,tj,tj1,result);
      JBCheb(x,-3.606261e-02,tj,tj1,result);
      JBCheb(x,7.310869e-03,tj,tj1,result);
      JBCheb(x,-3.320115e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(5.715445e-01*(s-8.000000e+00))-6.845834e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 12                        |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl12(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=1.0000)
     {
      x=2*(s-0.000000)/1.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-2.736742e-01,tj,tj1,result);
      JBCheb(x,-3.657836e-01,tj,tj1,result);
      JBCheb(x,-1.047209e-01,tj,tj1,result);
      JBCheb(x,-1.319599e-02,tj,tj1,result);
      JBCheb(x,-5.545631e-04,tj,tj1,result);
      JBCheb(x,9.280445e-05,tj,tj1,result);
      JBCheb(x,2.815679e-05,tj,tj1,result);
      JBCheb(x,-2.213519e-05,tj,tj1,result);
      JBCheb(x,1.256838e-05,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=3.0000)
     {
      x=2*(s-1.000000)/2.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-2.573947e+00,tj,tj1,result);
      JBCheb(x,-1.515287e+00,tj,tj1,result);
      JBCheb(x,3.611880e-01,tj,tj1,result);
      JBCheb(x,-3.271311e-02,tj,tj1,result);
      JBCheb(x,-6.495815e-02,tj,tj1,result);
      JBCheb(x,4.141186e-02,tj,tj1,result);
      JBCheb(x,7.180886e-04,tj,tj1,result);
      JBCheb(x,-1.388211e-02,tj,tj1,result);
      JBCheb(x,4.890761e-03,tj,tj1,result);
      JBCheb(x,3.233175e-03,tj,tj1,result);
      JBCheb(x,-2.946156e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=12.0000)
     {
      x=2*(s-3.000000)/9.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-5.947819e+00,tj,tj1,result);
      JBCheb(x,-2.034157e+00,tj,tj1,result);
      JBCheb(x,6.878986e-02,tj,tj1,result);
      JBCheb(x,-4.078603e-02,tj,tj1,result);
      JBCheb(x,6.990977e-03,tj,tj1,result);
      JBCheb(x,-2.866215e-03,tj,tj1,result);
      JBCheb(x,3.897866e-03,tj,tj1,result);
      JBCheb(x,2.512252e-03,tj,tj1,result);
      JBCheb(x,2.073743e-03,tj,tj1,result);
      JBCheb(x,3.022621e-03,tj,tj1,result);
      JBCheb(x,1.501343e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(2.877243e-01*(s-1.200000e+01))-7.936839e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 13                        |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl13(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=1.0000)
     {
      x=2*(s-0.000000)/1.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-2.713276e-01,tj,tj1,result);
      JBCheb(x,-3.557541e-01,tj,tj1,result);
      JBCheb(x,-9.459092e-02,tj,tj1,result);
      JBCheb(x,-1.044145e-02,tj,tj1,result);
      JBCheb(x,-2.546132e-04,tj,tj1,result);
      JBCheb(x,1.002374e-04,tj,tj1,result);
      JBCheb(x,2.349456e-05,tj,tj1,result);
      JBCheb(x,-7.025669e-05,tj,tj1,result);
      JBCheb(x,-1.590242e-05,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=3.0000)
     {
      x=2*(s-1.000000)/2.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-2.454383e+00,tj,tj1,result);
      JBCheb(x,-1.467539e+00,tj,tj1,result);
      JBCheb(x,3.270774e-01,tj,tj1,result);
      JBCheb(x,-8.075763e-03,tj,tj1,result);
      JBCheb(x,-6.611647e-02,tj,tj1,result);
      JBCheb(x,2.990785e-02,tj,tj1,result);
      JBCheb(x,8.109212e-03,tj,tj1,result);
      JBCheb(x,-1.135031e-02,tj,tj1,result);
      JBCheb(x,5.915919e-04,tj,tj1,result);
      JBCheb(x,3.522390e-03,tj,tj1,result);
      JBCheb(x,-1.144701e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=13.0000)
     {
      x=2*(s-3.000000)/10.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-5.736127e+00,tj,tj1,result);
      JBCheb(x,-1.920809e+00,tj,tj1,result);
      JBCheb(x,1.175858e-01,tj,tj1,result);
      JBCheb(x,-4.002049e-02,tj,tj1,result);
      JBCheb(x,1.158966e-02,tj,tj1,result);
      JBCheb(x,-3.157781e-03,tj,tj1,result);
      JBCheb(x,2.762172e-03,tj,tj1,result);
      JBCheb(x,5.780347e-04,tj,tj1,result);
      JBCheb(x,-1.193310e-03,tj,tj1,result);
      JBCheb(x,-2.442421e-05,tj,tj1,result);
      JBCheb(x,2.547756e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(2.799944e-01*(s-1.300000e+01))-7.566269e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 14                        |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl14(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=1.0000)
     {
      x=2*(s-0.000000)/1.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-2.698527e-01,tj,tj1,result);
      JBCheb(x,-3.479081e-01,tj,tj1,result);
      JBCheb(x,-8.640733e-02,tj,tj1,result);
      JBCheb(x,-8.466899e-03,tj,tj1,result);
      JBCheb(x,-1.469485e-04,tj,tj1,result);
      JBCheb(x,2.150009e-05,tj,tj1,result);
      JBCheb(x,1.965975e-05,tj,tj1,result);
      JBCheb(x,-4.710210e-05,tj,tj1,result);
      JBCheb(x,-1.327808e-05,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=3.0000)
     {
      x=2*(s-1.000000)/2.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-2.350359e+00,tj,tj1,result);
      JBCheb(x,-1.421365e+00,tj,tj1,result);
      JBCheb(x,2.960468e-01,tj,tj1,result);
      JBCheb(x,1.149167e-02,tj,tj1,result);
      JBCheb(x,-6.361109e-02,tj,tj1,result);
      JBCheb(x,1.976022e-02,tj,tj1,result);
      JBCheb(x,1.082700e-02,tj,tj1,result);
      JBCheb(x,-8.563328e-03,tj,tj1,result);
      JBCheb(x,-1.453123e-03,tj,tj1,result);
      JBCheb(x,2.917559e-03,tj,tj1,result);
      JBCheb(x,-1.151067e-05,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=15.0000)
     {
      x=2*(s-3.000000)/12.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-5.746892e+00,tj,tj1,result);
      JBCheb(x,-2.010441e+00,tj,tj1,result);
      JBCheb(x,1.566146e-01,tj,tj1,result);
      JBCheb(x,-5.129690e-02,tj,tj1,result);
      JBCheb(x,1.929724e-02,tj,tj1,result);
      JBCheb(x,-2.524227e-03,tj,tj1,result);
      JBCheb(x,3.192933e-03,tj,tj1,result);
      JBCheb(x,-4.254730e-04,tj,tj1,result);
      JBCheb(x,1.620685e-03,tj,tj1,result);
      JBCheb(x,7.289618e-04,tj,tj1,result);
      JBCheb(x,-2.112350e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(2.590621e-01*(s-1.500000e+01))-7.632238e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 15                        |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl15(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=2.0000)
     {
      x=2*(s-0.000000)/2.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.043660e+00,tj,tj1,result);
      JBCheb(x,-1.361653e+00,tj,tj1,result);
      JBCheb(x,-3.009497e-01,tj,tj1,result);
      JBCheb(x,4.951784e-02,tj,tj1,result);
      JBCheb(x,4.377903e-02,tj,tj1,result);
      JBCheb(x,1.003253e-02,tj,tj1,result);
      JBCheb(x,-1.271309e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result 
      return(result);
     }
//--- check
   if(s<=5.0000)
     {
      x=2*(s-2.000000)/3.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-3.582778e+00,tj,tj1,result);
      JBCheb(x,-8.349578e-01,tj,tj1,result);
      JBCheb(x,9.476514e-02,tj,tj1,result);
      JBCheb(x,-2.717385e-02,tj,tj1,result);
      JBCheb(x,1.222591e-02,tj,tj1,result);
      JBCheb(x,-6.635124e-03,tj,tj1,result);
      JBCheb(x,2.815993e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result 
      return(result);
     }
//--- check
   if(s<=17.0000)
     {
      x=2*(s-5.000000)/12.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-6.115476e+00,tj,tj1,result);
      JBCheb(x,-1.655936e+00,tj,tj1,result);
      JBCheb(x,8.404310e-02,tj,tj1,result);
      JBCheb(x,-2.663794e-02,tj,tj1,result);
      JBCheb(x,8.868618e-03,tj,tj1,result);
      JBCheb(x,1.381447e-03,tj,tj1,result);
      JBCheb(x,9.444801e-04,tj,tj1,result);
      JBCheb(x,-1.581503e-04,tj,tj1,result);
      JBCheb(x,-9.468696e-04,tj,tj1,result);
      JBCheb(x,1.728509e-03,tj,tj1,result);
      JBCheb(x,1.206470e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(1.927937e-01*(s-1.700000e+01))-7.700983e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 16                        |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl16(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=2.0000)
     {
      x=2*(s-0.000000)/2.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.002570e+00,tj,tj1,result);
      JBCheb(x,-1.298141e+00,tj,tj1,result);
      JBCheb(x,-2.832803e-01,tj,tj1,result);
      JBCheb(x,3.877026e-02,tj,tj1,result);
      JBCheb(x,3.539436e-02,tj,tj1,result);
      JBCheb(x,8.439658e-03,tj,tj1,result);
      JBCheb(x,-4.756911e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=5.0000)
     {
      x=2*(s-2.000000)/3.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-3.486198e+00,tj,tj1,result);
      JBCheb(x,-8.242944e-01,tj,tj1,result);
      JBCheb(x,1.020002e-01,tj,tj1,result);
      JBCheb(x,-3.130531e-02,tj,tj1,result);
      JBCheb(x,1.512373e-02,tj,tj1,result);
      JBCheb(x,-8.054876e-03,tj,tj1,result);
      JBCheb(x,3.556839e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=20.0000)
     {
      x=2*(s-5.000000)/15.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-6.241608e+00,tj,tj1,result);
      JBCheb(x,-1.832655e+00,tj,tj1,result);
      JBCheb(x,1.340545e-01,tj,tj1,result);
      JBCheb(x,-3.361143e-02,tj,tj1,result);
      JBCheb(x,1.283219e-02,tj,tj1,result);
      JBCheb(x,3.484549e-03,tj,tj1,result);
      JBCheb(x,1.805968e-03,tj,tj1,result);
      JBCheb(x,-2.057243e-03,tj,tj1,result);
      JBCheb(x,-1.454439e-03,tj,tj1,result);
      JBCheb(x,-2.177513e-03,tj,tj1,result);
      JBCheb(x,-1.819209e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(2.391580e-01*(s-2.000000e+01))-7.963205e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 17                        |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl17(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=3.0000)
     {
      x=2*(s-0.000000)/3.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.566973e+00,tj,tj1,result);
      JBCheb(x,-1.810330e+00,tj,tj1,result);
      JBCheb(x,-4.840039e-02,tj,tj1,result);
      JBCheb(x,2.337294e-01,tj,tj1,result);
      JBCheb(x,-5.383549e-04,tj,tj1,result);
      JBCheb(x,-5.556515e-02,tj,tj1,result);
      JBCheb(x,-8.656965e-03,tj,tj1,result);
      JBCheb(x,1.404569e-02,tj,tj1,result);
      JBCheb(x,6.447867e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=6.0000)
     {
      x=2*(s-3.000000)/3.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-3.905684e+00,tj,tj1,result);
      JBCheb(x,-6.222920e-01,tj,tj1,result);
      JBCheb(x,4.146667e-02,tj,tj1,result);
      JBCheb(x,-4.809176e-03,tj,tj1,result);
      JBCheb(x,1.057028e-03,tj,tj1,result);
      JBCheb(x,-1.211838e-04,tj,tj1,result);
      JBCheb(x,-4.099683e-04,tj,tj1,result);
      JBCheb(x,1.161105e-04,tj,tj1,result);
      JBCheb(x,2.225465e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=24.0000)
     {
      x=2*(s-6.000000)/18.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-6.594282e+00,tj,tj1,result);
      JBCheb(x,-1.917838e+00,tj,tj1,result);
      JBCheb(x,1.455980e-01,tj,tj1,result);
      JBCheb(x,-2.999589e-02,tj,tj1,result);
      JBCheb(x,5.604263e-03,tj,tj1,result);
      JBCheb(x,-3.484445e-03,tj,tj1,result);
      JBCheb(x,-1.819937e-03,tj,tj1,result);
      JBCheb(x,-2.930390e-03,tj,tj1,result);
      JBCheb(x,2.771761e-04,tj,tj1,result);
      JBCheb(x,-6.232581e-04,tj,tj1,result);
      JBCheb(x,-7.029083e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(2.127771e-01*(s-2.400000e+01))-8.400197e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 18                        |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl18(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=3.0000)
     {
      x=2*(s-0.000000)/3.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.526802e+00,tj,tj1,result);
      JBCheb(x,-1.762373e+00,tj,tj1,result);
      JBCheb(x,-5.598890e-02,tj,tj1,result);
      JBCheb(x,2.189437e-01,tj,tj1,result);
      JBCheb(x,5.971721e-03,tj,tj1,result);
      JBCheb(x,-4.823067e-02,tj,tj1,result);
      JBCheb(x,-1.064501e-02,tj,tj1,result);
      JBCheb(x,1.014932e-02,tj,tj1,result);
      JBCheb(x,5.953513e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=6.0000)
     {
      x=2*(s-3.000000)/3.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-3.818669e+00,tj,tj1,result);
      JBCheb(x,-6.070918e-01,tj,tj1,result);
      JBCheb(x,4.277196e-02,tj,tj1,result);
      JBCheb(x,-4.879817e-03,tj,tj1,result);
      JBCheb(x,6.887357e-04,tj,tj1,result);
      JBCheb(x,1.638451e-05,tj,tj1,result);
      JBCheb(x,1.502800e-04,tj,tj1,result);
      JBCheb(x,-3.165796e-05,tj,tj1,result);
      JBCheb(x,5.034960e-05,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result 
      return(result);
     }
//--- check
   if(s<=20.0000)
     {
      x=2*(s-6.000000)/14.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-6.010656e+00,tj,tj1,result);
      JBCheb(x,-1.496296e+00,tj,tj1,result);
      JBCheb(x,1.002227e-01,tj,tj1,result);
      JBCheb(x,-2.338250e-02,tj,tj1,result);
      JBCheb(x,4.137036e-03,tj,tj1,result);
      JBCheb(x,-2.586202e-03,tj,tj1,result);
      JBCheb(x,-9.736384e-04,tj,tj1,result);
      JBCheb(x,1.332251e-03,tj,tj1,result);
      JBCheb(x,1.877982e-03,tj,tj1,result);
      JBCheb(x,-1.160963e-05,tj,tj1,result);
      JBCheb(x,-2.547247e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result  
      return(result);
     }
   result=-(1.684623e-01*(s-2.000000e+01))-7.428883e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 19                        |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl19(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=3.0000)
     {
      x=2*(s-0.000000)/3.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.490213e+00,tj,tj1,result);
      JBCheb(x,-1.719633e+00,tj,tj1,result);
      JBCheb(x,-6.459123e-02,tj,tj1,result);
      JBCheb(x,2.034878e-01,tj,tj1,result);
      JBCheb(x,1.113868e-02,tj,tj1,result);
      JBCheb(x,-4.030922e-02,tj,tj1,result);
      JBCheb(x,-1.054022e-02,tj,tj1,result);
      JBCheb(x,7.525623e-03,tj,tj1,result);
      JBCheb(x,5.277360e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=6.0000)
     {
      x=2*(s-3.000000)/3.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-3.744750e+00,tj,tj1,result);
      JBCheb(x,-5.977749e-01,tj,tj1,result);
      JBCheb(x,4.223716e-02,tj,tj1,result);
      JBCheb(x,-5.363889e-03,tj,tj1,result);
      JBCheb(x,5.711774e-04,tj,tj1,result);
      JBCheb(x,-5.557257e-04,tj,tj1,result);
      JBCheb(x,4.254794e-04,tj,tj1,result);
      JBCheb(x,9.034207e-05,tj,tj1,result);
      JBCheb(x,5.498107e-05,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=20.0000)
     {
      x=2*(s-6.000000)/14.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-5.872768e+00,tj,tj1,result);
      JBCheb(x,-1.430689e+00,tj,tj1,result);
      JBCheb(x,1.136575e-01,tj,tj1,result);
      JBCheb(x,-1.726627e-02,tj,tj1,result);
      JBCheb(x,3.421110e-03,tj,tj1,result);
      JBCheb(x,-1.581510e-03,tj,tj1,result);
      JBCheb(x,-5.559520e-04,tj,tj1,result);
      JBCheb(x,-6.838208e-04,tj,tj1,result);
      JBCheb(x,8.428839e-04,tj,tj1,result);
      JBCheb(x,-7.170682e-04,tj,tj1,result);
      JBCheb(x,-6.006647e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(1.539373e-01*(s-2.000000e+01))-7.206941e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 20                        |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl20(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=4.0000)
     {
      x=2*(s-0.000000)/4.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.854794e+00,tj,tj1,result);
      JBCheb(x,-1.948947e+00,tj,tj1,result);
      JBCheb(x,1.632184e-01,tj,tj1,result);
      JBCheb(x,2.139397e-01,tj,tj1,result);
      JBCheb(x,-1.006237e-01,tj,tj1,result);
      JBCheb(x,-3.810031e-02,tj,tj1,result);
      JBCheb(x,3.573620e-02,tj,tj1,result);
      JBCheb(x,9.951242e-03,tj,tj1,result);
      JBCheb(x,-1.274092e-02,tj,tj1,result);
      JBCheb(x,-3.464196e-03,tj,tj1,result);
      JBCheb(x,4.882139e-03,tj,tj1,result);
      JBCheb(x,1.575144e-03,tj,tj1,result);
      JBCheb(x,-1.822804e-03,tj,tj1,result);
      JBCheb(x,-7.061348e-04,tj,tj1,result);
      JBCheb(x,5.908404e-04,tj,tj1,result);
      JBCheb(x,1.978353e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=15.0000)
     {
      x=2*(s-4.000000)/11.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-5.030989e+00,tj,tj1,result);
      JBCheb(x,-1.327151e+00,tj,tj1,result);
      JBCheb(x,1.346404e-01,tj,tj1,result);
      JBCheb(x,-2.840051e-02,tj,tj1,result);
      JBCheb(x,7.578551e-03,tj,tj1,result);
      JBCheb(x,-9.813886e-04,tj,tj1,result);
      JBCheb(x,5.905973e-05,tj,tj1,result);
      JBCheb(x,-5.358489e-04,tj,tj1,result);
      JBCheb(x,-3.450795e-04,tj,tj1,result);
      JBCheb(x,-6.941157e-04,tj,tj1,result);
      JBCheb(x,-7.432418e-04,tj,tj1,result);
      JBCheb(x,-2.070537e-04,tj,tj1,result);
      JBCheb(x,9.375654e-04,tj,tj1,result);
      JBCheb(x,5.367378e-04,tj,tj1,result);
      JBCheb(x,9.890859e-04,tj,tj1,result);
      JBCheb(x,6.679782e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=25.0000)
     {
      x=2*(s-15.000000)/10.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-7.015854e+00,tj,tj1,result);
      JBCheb(x,-7.487737e-01,tj,tj1,result);
      JBCheb(x,2.244254e-02,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(1.318007e-01*(s-2.500000e+01))-7.742185e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 30                        |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl30(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=4.0000)
     {
      x=2*(s-0.000000)/4.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.630822e+00,tj,tj1,result);
      JBCheb(x,-1.724298e+00,tj,tj1,result);
      JBCheb(x,7.872756e-02,tj,tj1,result);
      JBCheb(x,1.658268e-01,tj,tj1,result);
      JBCheb(x,-3.573597e-02,tj,tj1,result);
      JBCheb(x,-2.994157e-02,tj,tj1,result);
      JBCheb(x,5.994825e-03,tj,tj1,result);
      JBCheb(x,7.394303e-03,tj,tj1,result);
      JBCheb(x,-5.785029e-04,tj,tj1,result);
      JBCheb(x,-1.990264e-03,tj,tj1,result);
      JBCheb(x,-1.037838e-04,tj,tj1,result);
      JBCheb(x,6.755546e-04,tj,tj1,result);
      JBCheb(x,1.774473e-04,tj,tj1,result);
      JBCheb(x,-2.821395e-04,tj,tj1,result);
      JBCheb(x,-1.392603e-04,tj,tj1,result);
      JBCheb(x,1.353313e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=15.0000)
     {
      x=2*(s-4.000000)/11.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-4.539322e+00,tj,tj1,result);
      JBCheb(x,-1.197018e+00,tj,tj1,result);
      JBCheb(x,1.396848e-01,tj,tj1,result);
      JBCheb(x,-2.804293e-02,tj,tj1,result);
      JBCheb(x,6.867928e-03,tj,tj1,result);
      JBCheb(x,-2.768758e-03,tj,tj1,result);
      JBCheb(x,5.211792e-04,tj,tj1,result);
      JBCheb(x,4.925799e-04,tj,tj1,result);
      JBCheb(x,5.046235e-04,tj,tj1,result);
      JBCheb(x,-9.536469e-05,tj,tj1,result);
      JBCheb(x,-6.489642e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=25.0000)
     {
      x=2*(s-15.000000)/10.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-6.263462e+00,tj,tj1,result);
      JBCheb(x,-6.177316e-01,tj,tj1,result);
      JBCheb(x,2.590637e-02,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(1.028212e-01*(s-2.500000e+01))-6.855288e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 50                        |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl50(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=4.0000)
     {
      x=2*(s-0.000000)/4.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.436279e+00,tj,tj1,result);
      JBCheb(x,-1.519711e+00,tj,tj1,result);
      JBCheb(x,1.148699e-02,tj,tj1,result);
      JBCheb(x,1.001204e-01,tj,tj1,result);
      JBCheb(x,-3.207620e-03,tj,tj1,result);
      JBCheb(x,-1.034778e-02,tj,tj1,result);
      JBCheb(x,-1.220322e-03,tj,tj1,result);
      JBCheb(x,1.033260e-03,tj,tj1,result);
      JBCheb(x,2.588280e-04,tj,tj1,result);
      JBCheb(x,-1.851653e-04,tj,tj1,result);
      JBCheb(x,-1.287733e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=15.0000)
     {
      x=2*(s-4.000000)/11.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-4.234645e+00,tj,tj1,result);
      JBCheb(x,-1.189127e+00,tj,tj1,result);
      JBCheb(x,1.429738e-01,tj,tj1,result);
      JBCheb(x,-3.058822e-02,tj,tj1,result);
      JBCheb(x,9.086776e-03,tj,tj1,result);
      JBCheb(x,-1.445783e-03,tj,tj1,result);
      JBCheb(x,1.311671e-03,tj,tj1,result);
      JBCheb(x,-7.261298e-04,tj,tj1,result);
      JBCheb(x,6.496987e-04,tj,tj1,result);
      JBCheb(x,2.605249e-04,tj,tj1,result);
      JBCheb(x,8.162282e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=25.0000)
     {
      x=2*(s-15.000000)/10.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-5.921095e+00,tj,tj1,result);
      JBCheb(x,-5.888603e-01,tj,tj1,result);
      JBCheb(x,3.080113e-02,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(9.313116e-02*(s-2.500000e+01))-6.479154e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 65                        |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl65(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=4.0000)
     {
      x=2*(s-0.000000)/4.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.360024e+00,tj,tj1,result);
      JBCheb(x,-1.434631e+00,tj,tj1,result);
      JBCheb(x,-6.514580e-03,tj,tj1,result);
      JBCheb(x,7.332038e-02,tj,tj1,result);
      JBCheb(x,1.158197e-03,tj,tj1,result);
      JBCheb(x,-5.121233e-03,tj,tj1,result);
      JBCheb(x,-1.051056e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=15.0000)
     {
      x=2*(s-4.000000)/11.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-4.148601e+00,tj,tj1,result);
      JBCheb(x,-1.214233e+00,tj,tj1,result);
      JBCheb(x,1.487977e-01,tj,tj1,result);
      JBCheb(x,-3.424720e-02,tj,tj1,result);
      JBCheb(x,1.116715e-02,tj,tj1,result);
      JBCheb(x,-4.043152e-03,tj,tj1,result);
      JBCheb(x,1.718149e-03,tj,tj1,result);
      JBCheb(x,-1.313701e-03,tj,tj1,result);
      JBCheb(x,3.097305e-04,tj,tj1,result);
      JBCheb(x,2.181031e-04,tj,tj1,result);
      JBCheb(x,1.256975e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=25.0000)
     {
      x=2*(s-15.000000)/10.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-5.858951e+00,tj,tj1,result);
      JBCheb(x,-5.895179e-01,tj,tj1,result);
      JBCheb(x,2.933237e-02,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(9.443768e-02*(s-2.500000e+01))-6.419137e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 100                       |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl100(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=4.0000)
     {
      x=2*(s-0.000000)/4.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.257021e+00,tj,tj1,result);
      JBCheb(x,-1.313418e+00,tj,tj1,result);
      JBCheb(x,-1.628931e-02,tj,tj1,result);
      JBCheb(x,4.264287e-02,tj,tj1,result);
      JBCheb(x,1.518487e-03,tj,tj1,result);
      JBCheb(x,-1.499826e-03,tj,tj1,result);
      JBCheb(x,-4.836044e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=15.0000)
     {
      x=2*(s-4.000000)/11.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-4.056508e+00,tj,tj1,result);
      JBCheb(x,-1.279690e+00,tj,tj1,result);
      JBCheb(x,1.665746e-01,tj,tj1,result);
      JBCheb(x,-4.290012e-02,tj,tj1,result);
      JBCheb(x,1.487632e-02,tj,tj1,result);
      JBCheb(x,-5.704465e-03,tj,tj1,result);
      JBCheb(x,2.211669e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=25.0000)
     {
      x=2*(s-15.000000)/10.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-5.866099e+00,tj,tj1,result);
      JBCheb(x,-6.399767e-01,tj,tj1,result);
      JBCheb(x,2.498208e-02,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(1.080097e-01*(s-2.500000e+01))-6.481094e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 130                       |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl130(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=4.0000)
     {
      x=2*(s-0.000000)/4.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.207999e+00,tj,tj1,result);
      JBCheb(x,-1.253864e+00,tj,tj1,result);
      JBCheb(x,-1.618032e-02,tj,tj1,result);
      JBCheb(x,3.112729e-02,tj,tj1,result);
      JBCheb(x,1.210546e-03,tj,tj1,result);
      JBCheb(x,-4.732602e-04,tj,tj1,result);
      JBCheb(x,-2.410527e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=15.0000)
     {
      x=2*(s-4.000000)/11.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-4.026324e+00,tj,tj1,result);
      JBCheb(x,-1.331990e+00,tj,tj1,result);
      JBCheb(x,1.779129e-01,tj,tj1,result);
      JBCheb(x,-4.674749e-02,tj,tj1,result);
      JBCheb(x,1.669077e-02,tj,tj1,result);
      JBCheb(x,-5.679136e-03,tj,tj1,result);
      JBCheb(x,8.833221e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=25.0000)
     {
      x=2*(s-15.000000)/10.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-5.893951e+00,tj,tj1,result);
      JBCheb(x,-6.475304e-01,tj,tj1,result);
      JBCheb(x,3.116734e-02,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(1.045722e-01*(s-2.500000e+01))-6.510314e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 200                       |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl200(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=4.0000)
     {
      x=2*(s-0.000000)/4.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.146155e+00,tj,tj1,result);
      JBCheb(x,-1.177398e+00,tj,tj1,result);
      JBCheb(x,-1.297970e-02,tj,tj1,result);
      JBCheb(x,1.869745e-02,tj,tj1,result);
      JBCheb(x,1.717288e-04,tj,tj1,result);
      JBCheb(x,-1.982108e-04,tj,tj1,result);
      JBCheb(x,6.427636e-05,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=15.0000)
     {
      x=2*(s-4.000000)/11.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-4.034235e+00,tj,tj1,result);
      JBCheb(x,-1.455006e+00,tj,tj1,result);
      JBCheb(x,1.942996e-01,tj,tj1,result);
      JBCheb(x,-4.973795e-02,tj,tj1,result);
      JBCheb(x,1.418812e-02,tj,tj1,result);
      JBCheb(x,-3.156778e-03,tj,tj1,result);
      JBCheb(x,4.896705e-05,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=25.0000)
     {
      x=2*(s-15.000000)/10.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-6.086071e+00,tj,tj1,result);
      JBCheb(x,-7.152176e-01,tj,tj1,result);
      JBCheb(x,3.725393e-02,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(1.132404e-01*(s-2.500000e+01))-6.764034e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 301                       |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl301(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=4.0000)
     {
      x=2*(s-0.000000)/4.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.104290e+00,tj,tj1,result);
      JBCheb(x,-1.125800e+00,tj,tj1,result);
      JBCheb(x,-9.595847e-03,tj,tj1,result);
      JBCheb(x,1.219666e-02,tj,tj1,result);
      JBCheb(x,1.502210e-04,tj,tj1,result);
      JBCheb(x,-6.414543e-05,tj,tj1,result);
      JBCheb(x,6.754115e-05,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=15.0000)
     {
      x=2*(s-4.000000)/11.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-4.065955e+00,tj,tj1,result);
      JBCheb(x,-1.582060e+00,tj,tj1,result);
      JBCheb(x,2.004472e-01,tj,tj1,result);
      JBCheb(x,-4.709092e-02,tj,tj1,result);
      JBCheb(x,1.105779e-02,tj,tj1,result);
      JBCheb(x,1.197391e-03,tj,tj1,result);
      JBCheb(x,-8.386780e-04,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=25.0000)
     {
      x=2*(s-15.000000)/10.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-6.311384e+00,tj,tj1,result);
      JBCheb(x,-7.918763e-01,tj,tj1,result);
      JBCheb(x,3.626584e-02,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(1.293626e-01*(s-2.500000e+01))-7.066995e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 501                       |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl501(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=4.0000)
     {
      x=2*(s-0.000000)/4.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.067426e+00,tj,tj1,result);
      JBCheb(x,-1.079765e+00,tj,tj1,result);
      JBCheb(x,-5.463005e-03,tj,tj1,result);
      JBCheb(x,6.875659e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   if(s<=15.0000)
     {
      x=2*(s-4.000000)/11.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-4.127574e+00,tj,tj1,result);
      JBCheb(x,-1.740694e+00,tj,tj1,result);
      JBCheb(x,2.044502e-01,tj,tj1,result);
      JBCheb(x,-3.746714e-02,tj,tj1,result);
      JBCheb(x,3.810594e-04,tj,tj1,result);
      JBCheb(x,1.197111e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=25.0000)
     {
      x=2*(s-15.000000)/10.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-6.628194e+00,tj,tj1,result);
      JBCheb(x,-8.846221e-01,tj,tj1,result);
      JBCheb(x,4.386405e-02,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(1.418332e-01*(s-2.500000e+01))-7.468952e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 701                       |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl701(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=4.0000)
     {
      x=2*(s-0.000000)/4.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.050999e+00,tj,tj1,result);
      JBCheb(x,-1.059769e+00,tj,tj1,result);
      JBCheb(x,-3.922680e-03,tj,tj1,result);
      JBCheb(x,4.847054e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=15.0000)
     {
      x=2*(s-4.000000)/11.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-4.192182e+00,tj,tj1,result);
      JBCheb(x,-1.860007e+00,tj,tj1,result);
      JBCheb(x,1.963942e-01,tj,tj1,result);
      JBCheb(x,-2.838711e-02,tj,tj1,result);
      JBCheb(x,-2.893112e-04,tj,tj1,result);
      JBCheb(x,2.159788e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=25.0000)
     {
      x=2*(s-15.000000)/10.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-6.917851e+00,tj,tj1,result);
      JBCheb(x,-9.817020e-01,tj,tj1,result);
      JBCheb(x,5.383727e-02,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(1.532706e-01*(s-2.500000e+01))-7.845715e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tabulation at the size of the array is 1401                      |
//+------------------------------------------------------------------+
static double CJarqueBera::JBTbl1401(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- check
   if(s<=4.0000)
     {
      x=2*(s-0.000000)/4.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-1.026266e+00,tj,tj1,result);
      JBCheb(x,-1.030061e+00,tj,tj1,result);
      JBCheb(x,-1.259222e-03,tj,tj1,result);
      JBCheb(x,2.536254e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result 
      return(result);
     }
//--- check
   if(s<=15.0000)
     {
      x=2*(s-4.000000)/11.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-4.329849e+00,tj,tj1,result);
      JBCheb(x,-2.095443e+00,tj,tj1,result);
      JBCheb(x,1.759363e-01,tj,tj1,result);
      JBCheb(x,-7.751359e-03,tj,tj1,result);
      JBCheb(x,-6.124368e-03,tj,tj1,result);
      JBCheb(x,-1.793114e-03,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
//--- check
   if(s<=25.0000)
     {
      x=2*(s-15.000000)/10.000000-1;
      tj=1;
      tj1=x;
      JBCheb(x,-7.544330e+00,tj,tj1,result);
      JBCheb(x,-1.225382e+00,tj,tj1,result);
      JBCheb(x,5.392349e-02,tj,tj1,result);
      //--- check
      if(result>0)
         result=0;
      //--- return result
      return(result);
     }
   result=-(2.019375e-01*(s-2.500000e+01))-8.715788e+00;
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Mann-Whitney U-test                                              |
//+------------------------------------------------------------------+
class CMannWhitneyU
  {
private:
   static void       UCheb(const double x,const double c,double &tj,double &tj1,double &r);
   static double     UThreePointInterpolate(const double p1,const double p2,const double p3,const int n);
   static double     USigma(double s,const int n1,const int n2);
   static double     USigma000(const int n1,const int n2);
   static double     USigma075(const int n1,const int n2);
   static double     USigma150(const int n1,const int n2);
   static double     USigma225(const int n1,const int n2);
   static double     USigma300(const int n1,const int n2);
   static double     USigma333(const int n1,const int n2);
   static double     USigma367(const int n1,const int n2);
   static double     USigma400(const int n1,const int n2);
   static double     UTbln5n5(const double s);
   static double     UTbln5n6(const double s);
   static double     UTbln5n7(const double s);
   static double     UTbln5n8(const double s);
   static double     UTbln5n9(const double s);
   static double     UTbln5n10(const double s);
   static double     UTbln5n11(const double s);
   static double     UTbln5n12(const double s);
   static double     UTbln5n13(const double s);
   static double     UTbln5n14(const double s);
   static double     UTbln5n15(const double s);
   static double     UTbln5n16(const double s);
   static double     UTbln5n17(const double s);
   static double     UTbln5n18(const double s);
   static double     UTbln5n19(const double s);
   static double     UTbln5n20(const double s);
   static double     UTbln5n21(const double s);
   static double     UTbln5n22(const double s);
   static double     UTbln5n23(const double s);
   static double     UTbln5n24(const double s);
   static double     UTbln5n25(const double s);
   static double     UTbln5n26(const double s);
   static double     UTbln5n27(const double s);
   static double     UTbln5n28(const double s);
   static double     UTbln5n29(const double s);
   static double     UTbln5n30(const double s);
   static double     UTbln5n100(const double s);
   static double     UTbln6n6(const double s);
   static double     UTbln6n7(const double s);
   static double     UTbln6n8(const double s);
   static double     UTbln6n9(const double s);
   static double     UTbln6n10(const double s);
   static double     UTbln6n11(const double s);
   static double     UTbln6n12(const double s);
   static double     UTbln6n13(const double s);
   static double     UTbln6n14(const double s);
   static double     UTbln6n15(const double s);
   static double     UTbln6n30(const double s);
   static double     UTbln6n100(const double s);
   static double     UTbln7n7(const double s);
   static double     UTbln7n8(const double s);
   static double     UTbln7n9(const double s);
   static double     UTbln7n10(const double s);
   static double     UTbln7n11(const double s);
   static double     UTbln7n12(const double s);
   static double     UTbln7n13(const double s);
   static double     UTbln7n14(const double s);
   static double     UTbln7n15(const double s);
   static double     UTbln7n30(const double s);
   static double     UTbln7n100(const double s);
   static double     UTbln8n8(const double s);
   static double     UTbln8n9(const double s);
   static double     UTbln8n10(const double s);
   static double     UTbln8n11(const double s);
   static double     UTbln8n12(const double s);
   static double     UTbln8n13(const double s);
   static double     UTbln8n14(const double s);
   static double     UTbln8n15(const double s);
   static double     UTbln8n30(const double s);
   static double     UTbln8n100(const double s);
   static double     UTbln9n9(const double s);
   static double     UTbln9n10(const double s);
   static double     UTbln9n11(const double s);
   static double     UTbln9n12(const double s);
   static double     UTbln9n13(const double s);
   static double     UTbln9n14(const double s);
   static double     UTbln9n15(const double s);
   static double     UTbln9n30(const double s);
   static double     UTbln9n100(const double s);
   static double     UTbln10n10(const double s);
   static double     UTbln10n11(const double s);
   static double     UTbln10n12(const double s);
   static double     UTbln10n13(const double s);
   static double     UTbln10n14(const double s);
   static double     UTbln10n15(const double s);
   static double     UTbln10n30(const double s);
   static double     UTbln10n100(const double s);
   static double     UTbln11n11(const double s);
   static double     UTbln11n12(const double s);
   static double     UTbln11n13(const double s);
   static double     UTbln11n14(const double s);
   static double     UTbln11n15(const double s);
   static double     UTbln11n30(const double s);
   static double     UTbln11n100(const double s);
   static double     UTbln12n12(const double s);
   static double     UTbln12n13(const double s);
   static double     UTbln12n14(const double s);
   static double     UTbln12n15(const double s);
   static double     UTbln12n30(const double s);
   static double     UTbln12n100(const double s);
   static double     UTbln13n13(const double s);
   static double     UTbln13n14(const double s);
   static double     UTbln13n15(const double s);
   static double     UTbln13n30(const double s);
   static double     UTbln13n100(const double s);
   static double     UTbln14n14(const double s);
   static double     UTbln14n15(const double s);
   static double     UTbln14n30(const double s);
   static double     UTbln14n100(const double s);
public:
   //--- constructor, destructor
                     CMannWhitneyU(void);
                    ~CMannWhitneyU(void);
   //--- method
   static void       CMannWhitneyUTest(const double &x[],const int n,const double &y[],const int m,double &bothTails,double &leftTail,double &rightTail);
  };
//+------------------------------------------------------------------+
//| Constructor without parameters                                   |
//+------------------------------------------------------------------+
CMannWhitneyU::CMannWhitneyU(void)
  {

  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMannWhitneyU::~CMannWhitneyU(void)
  {

  }
//+------------------------------------------------------------------+
//| Mann-Whitney U-test                                              |
//| This test checks hypotheses about whether X and Y are samples of |
//| two continuous distributions of the same shape and same median or|
//| whether their medians are different.                             |
//| The following tests are performed:                               |
//|     * two-tailed test (null hypothesis - the medians are equal)  |
//|     * left-tailed test (null hypothesis - the median of the first|
//|       sample is greater than or equal to the median of the second|
//|       sample)                                                    |
//|     * right-tailed test (null hypothesis - the median of the     |
//|       first sample is less than or equal to the median of the    |
//|       second sample).                                            |
//| Requirements:                                                    |
//|     * the samples are independent                                |
//|     * X and Y are continuous distributions (or discrete          |
//|       distributions well- approximating continuous distributions)|
//|     * distributions of X and Y have the  same  shape.  The  only |
//|       possible difference is their position (i.e. the value of   |
//|       the median)                                                |
//|     * the number of elements in each sample is not less than 5   |
//|     * the scale of measurement should be ordinal, interval or    |
//|       ratio (i.e. the test could not be applied to nominal       |
//|       variables).                                                |
//| The test is non-parametric and doesn't require distributions to  |
//| be normal.                                                       |
//| Input parameters:                                                |
//|     X   -   sample 1. Array whose index goes from 0 to N-1.      |
//|     N   -   size of the sample. N>=5                             |
//|     Y   -   sample 2. Array whose index goes from 0 to M-1.      |
//|     M   -   size of the sample. M>=5                             |
//| Output parameters:                                               |
//|     BothTails   -   p-value for two-tailed test.                 |
//|                     If BothTails is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//|     LeftTail    -   p-value for left-tailed test.                |
//|                     If LeftTail is less than the given           |
//|                     significance level, the null hypothesis is   |
//|                     rejected.                                    |
//|     RightTail   -   p-value for right-tailed test.               |
//|                     If RightTail is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//| To calculate p-values, special approximation is used. This       |
//| method lets us calculate p-values with satisfactory accuracy in  |
//| interval [0.0001, 1]. There is no approximation outside the      |
//| [0.0001, 1] interval. Therefore, if the significance level       |
//| outlies this interval, the test returns 0.0001.                  |
//| Relative precision of approximation of p-value:                  |
//| N          M          Max.err.   Rms.err.                        |
//| 5..10      N..10      1.4e-02    6.0e-04                         |
//| 5..10      N..100     2.2e-02    5.3e-06                         |
//| 10..15     N..15      1.0e-02    3.2e-04                         |
//| 10..15     N..100     1.0e-02    2.2e-05                         |
//| 15..100    N..100     6.1e-03    2.7e-06                         |
//| For N,M>100 accuracy checks weren't put into practice, but taking|
//| into account characteristics of asymptotic approximation used,   |
//| precision should not be sharply different from the values for    |
//| interval [5, 100].                                               |
//+------------------------------------------------------------------+
static void CMannWhitneyU::CMannWhitneyUTest(const double &x[],const int n,
                                             const double &y[],const int m,
                                             double &bothTails,double &leftTail,
                                             double &rightTail)
  {
//--- Prepare
   if(n<=4 || m<=4)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      return;
     }
//--- create variables
   int    i=0;
   int    j=0;
   int    k=0;
   int    t=0;
   double tmp=0;
   int    tmpi=0;
   int    ns=n+m;
   double r[];
   int    c[];
   double u=0;
   double p=0;
   double mp=0;
   double s=0;
   double sigma=0;
   double mu=0;
   int    tiecount=0;
   int    tiesize[];
//--- allocation
   ArrayResizeAL(r,ns);
   ArrayResizeAL(c,ns);
//--- fiiling arrays
   for(i=0;i<n;i++)
     {
      r[i]=x[i];
      c[i]=0;
     }
   for(i=0;i<m;i++)
     {
      r[n+i]=y[i];
      c[n+i]=1;
     }
//--- sort {R, C}
   if(ns!=1)
     {
      i=2;
      //--- cycle
      do
        {
         t=i;
         //--- cycle
         while(t!=1)
           {
            k=t/2;
            //--- check
            if(r[k-1]>=r[t-1])
               t=1;
            else
              {
               //--- change positions
               tmp=r[k-1];
               r[k-1]=r[t-1];
               r[t-1]=tmp;
               tmpi=c[k-1];
               c[k-1]=c[t-1];
               c[t-1]=tmpi;
               t=k;
              }
           }
         i++;
        }
      while(i<=ns);
      //--- change value
      i=ns-1;
      do
        {
         //--- change positions
         tmp=r[i];
         r[i]=r[0];
         r[0]=tmp;
         tmpi=c[i];
         c[i]=c[0];
         c[0]=tmpi;
         t=1;
         //--- cycle
         while(t!=0)
           {
            k=2*t;
            //--- check
            if(k>i)
               t=0;
            else
              {
               //--- check
               if(k<i)
                  if(r[k]>r[k-1])
                     k++;
               //--- check
               if(r[t-1]>=r[k-1])
                  t=0;
               else
                 {
                  //--- change positions
                  tmp=r[k-1];
                  r[k-1]=r[t-1];
                  r[t-1]=tmp;
                  tmpi=c[k-1];
                  c[k-1]=c[t-1];
                  c[t-1]=tmpi;
                  t=k;
                 }
              }
           }
         i--;
        }
      while(i>=1);
     }
//--- compute tied ranks
   i=0;
   tiecount=0;
   ArrayResizeAL(tiesize,ns-1+1);
//--- cycle
   while(i<ns)
     {
      j=i+1;
      while(j<ns)
        {
         //--- check
         if(r[j]!=r[i])
            break;
         j++;
        }
      for(k=i;k<j;k++)
         r[k]=1+(double)(i+j-1)/2.0;
      //--- change values
      tiesize[tiecount]=j-i;
      tiecount++;
      i=j;
     }
//--- Compute U
   u=0;
   for(i=0;i<ns;i++)
     {
      if(c[i]==0)
         u+=r[i];
     }
   u=n*m+n*(n+1)/2-u;
//--- Result
   mu=n*m/2.0;
   tmp=ns*(CMath::Sqr(ns)-1)/12;
   for(i=0;i<tiecount;i++)
      tmp-=tiesize[i]*(CMath::Sqr(tiesize[i])-1)/12;
//--- calculation sigma
   sigma=MathSqrt((double)(m*n)/(double)ns/(ns-1)*tmp);
   s=(u-mu)/sigma;
//--- check
   if(s<=0)
     {
      p=MathExp(USigma(-((u-mu)/sigma),n,m));
      mp=1-MathExp(USigma(-((u-1-mu)/sigma),n,m));
     }
   else
     {
      mp=MathExp(USigma((u-mu)/sigma,n,m));
      p=1-MathExp(USigma((u+1-mu)/sigma,n,m));
     }
//--- get parameters
   bothTails=MathMax(2*MathMin(p,mp),1.0E-4);
   leftTail=MathMax(mp,1.0E-4);
   rightTail=MathMax(p,1.0E-4);
  }
//+------------------------------------------------------------------+
//| Sequential Chebyshev interpolation.                              |
//+------------------------------------------------------------------+
static void CMannWhitneyU::UCheb(const double x,const double c,double &tj,
                                 double &tj1,double &r)
  {
//--- create variables
   double t;
//--- change values
   r=r+c*tj;
   t=2*x*tj1-tj;
   tj=tj1;
   tj1=t;
  }
//+------------------------------------------------------------------+
//| Three-point polynomial interpolation.                            |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UThreePointInterpolate(const double p1,
                                                    const double p2,
                                                    const double p3,
                                                    const int n)
  {
//--- create variables
   double t1;
   double t2;
   double t3;
   double t;
   double p12;
   double p23;
//--- interpolating
   t1=1.0/15.0;
   t2=1.0/30.0;
   t3=1.0/100.0;
   t=1.0/n;
   p12=((t-t2)*p1+(t1-t)*p2)/(t1-t2);
   p23=((t-t3)*p2+(t2-t)*p3)/(t2-t3);
//--- return result
   return(((t-t3)*p12+(t1-t)*p23)/(t1-t3));
  }
//+------------------------------------------------------------------+
//| Tail(0, N1, N2)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::USigma000(const int n1,const int n2)
  {
//--- create variables
   double p1;
   double p2;
   double p3;
//--- interpolating
   p1=UThreePointInterpolate(-6.76984e-01,-6.83700e-01,-6.89873e-01,n2);
   p2=UThreePointInterpolate(-6.83700e-01,-6.87311e-01,-6.90957e-01,n2);
   p3=UThreePointInterpolate(-6.89873e-01,-6.90957e-01,-6.92175e-01,n2);
//--- return result
   return(UThreePointInterpolate(p1,p2,p3,n1));
  }
//+------------------------------------------------------------------+
//| Tail(0.75, N1, N2)                                               |
//+------------------------------------------------------------------+
static double CMannWhitneyU::USigma075(const int n1,const int n2)
  {
//--- create variables
   double p1;
   double p2;
   double p3;
//--- interpolating
   p1=UThreePointInterpolate(-1.44500e+00,-1.45906e+00,-1.47063e+00,n2);
   p2=UThreePointInterpolate(-1.45906e+00,-1.46856e+00,-1.47644e+00,n2);
   p3=UThreePointInterpolate(-1.47063e+00,-1.47644e+00,-1.48100e+00,n2);
//--- return result
   return(UThreePointInterpolate(p1,p2,p3,n1));
  }
//+------------------------------------------------------------------+
//| Tail(1.5, N1, N2)                                                |
//+------------------------------------------------------------------+
static double CMannWhitneyU::USigma150(const int n1,const int n2)
  {
//--- create variables
   double p1;
   double p2;
   double p3;
//--- interpolating
   p1=UThreePointInterpolate(-2.65380e+00,-2.67352e+00,-2.69011e+00,n2);
   p2=UThreePointInterpolate(-2.67352e+00,-2.68591e+00,-2.69659e+00,n2);
   p3=UThreePointInterpolate(-2.69011e+00,-2.69659e+00,-2.70192e+00,n2);
//--- return result
   return(UThreePointInterpolate(p1,p2,p3,n1));
  }
//+------------------------------------------------------------------+
//| Tail(2.25, N1, N2)                                               |
//+------------------------------------------------------------------+
static double CMannWhitneyU::USigma225(const int n1,const int n2)
  {
//--- create variables
   double p1;
   double p2;
   double p3;
//--- interpolating
   p1=UThreePointInterpolate(-4.41465e+00,-4.42260e+00,-4.43702e+00,n2);
   p2=UThreePointInterpolate(-4.42260e+00,-4.41639e+00,-4.41928e+00,n2);
   p3=UThreePointInterpolate(-4.43702e+00,-4.41928e+00,-4.41030e+00,n2);
//--- return result
   return(UThreePointInterpolate(p1,p2,p3,n1));
  }
//+------------------------------------------------------------------+
//| Tail(3.0, N1, N2)                                                |
//+------------------------------------------------------------------+
static double CMannWhitneyU::USigma300(const int n1,const int n2)
  {
//--- create variables
   double p1;
   double p2;
   double p3;
//--- interpolating
   p1=UThreePointInterpolate(-6.89839e+00,-6.83477e+00,-6.82340e+00,n2);
   p2=UThreePointInterpolate(-6.83477e+00,-6.74559e+00,-6.71117e+00,n2);
   p3=UThreePointInterpolate(-6.82340e+00,-6.71117e+00,-6.64929e+00,n2);
//--- return result
   return(UThreePointInterpolate(p1,p2,p3,n1));
  }
//+------------------------------------------------------------------+
//| Tail(3.33, N1, N2)                                               |
//+------------------------------------------------------------------+
static double CMannWhitneyU::USigma333(const int n1,const int n2)
  {
//--- create variables
   double p1;
   double p2;
   double p3;
//--- interpolating
   p1=UThreePointInterpolate(-8.31272e+00,-8.17096e+00,-8.13125e+00,n2);
   p2=UThreePointInterpolate(-8.17096e+00,-8.00156e+00,-7.93245e+00,n2);
   p3=UThreePointInterpolate(-8.13125e+00,-7.93245e+00,-7.82502e+00,n2);
//--- return result
   return(UThreePointInterpolate(p1,p2,p3,n1));
  }
//+------------------------------------------------------------------+
//| Tail(3.66, N1, N2)                                               |
//+------------------------------------------------------------------+
static double CMannWhitneyU::USigma367(const int n1,const int n2)
  {
//--- create variables
   double p1;
   double p2;
   double p3;
//--- interpolating
   p1=UThreePointInterpolate(-9.98837e+00,-9.70844e+00,-9.62087e+00,n2);
   p2=UThreePointInterpolate(-9.70844e+00,-9.41156e+00,-9.28998e+00,n2);
   p3=UThreePointInterpolate(-9.62087e+00,-9.28998e+00,-9.11686e+00,n2);
//--- return result
   return(UThreePointInterpolate(p1,p2,p3,n1));
  }
//+------------------------------------------------------------------+
//| Tail(4.0, N1, N2)                                                |
//+------------------------------------------------------------------+
static double CMannWhitneyU::USigma400(const int n1,const int n2)
  {
//--- create variables
   double p1;
   double p2;
   double p3;
//--- interpolating
   p1=UThreePointInterpolate(-1.20250e+01,-1.14911e+01,-1.13231e+01,n2);
   p2=UThreePointInterpolate(-1.14911e+01,-1.09927e+01,-1.07937e+01,n2);
   p3=UThreePointInterpolate(-1.13231e+01,-1.07937e+01,-1.05285e+01,n2);
//--- return result
   return(UThreePointInterpolate(p1,p2,p3,n1));
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 5)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n5(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/2.611165e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-2.596264e+00,tj,tj1,result);
   UCheb(x,-2.412086e+00,tj,tj1,result);
   UCheb(x,-4.858542e-01,tj,tj1,result);
   UCheb(x,-5.614282e-02,tj,tj1,result);
   UCheb(x,3.372686e-03,tj,tj1,result);
   UCheb(x,8.524731e-03,tj,tj1,result);
   UCheb(x,4.435331e-03,tj,tj1,result);
   UCheb(x,1.284665e-03,tj,tj1,result);
   UCheb(x,4.184141e-03,tj,tj1,result);
   UCheb(x,5.298360e-03,tj,tj1,result);
   UCheb(x,7.447272e-04,tj,tj1,result);
   UCheb(x,-3.938769e-03,tj,tj1,result);
   UCheb(x,-4.276205e-03,tj,tj1,result);
   UCheb(x,-1.138481e-03,tj,tj1,result);
   UCheb(x,8.684625e-04,tj,tj1,result);
   UCheb(x,1.558104e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 6)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n6(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/2.738613e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-2.810459e+00,tj,tj1,result);
   UCheb(x,-2.684429e+00,tj,tj1,result);
   UCheb(x,-5.712858e-01,tj,tj1,result);
   UCheb(x,-8.009324e-02,tj,tj1,result);
   UCheb(x,-6.644391e-03,tj,tj1,result);
   UCheb(x,6.034173e-03,tj,tj1,result);
   UCheb(x,4.953498e-03,tj,tj1,result);
   UCheb(x,3.279293e-03,tj,tj1,result);
   UCheb(x,3.563485e-03,tj,tj1,result);
   UCheb(x,4.971952e-03,tj,tj1,result);
   UCheb(x,3.506309e-03,tj,tj1,result);
   UCheb(x,-1.541406e-04,tj,tj1,result);
   UCheb(x,-3.283205e-03,tj,tj1,result);
   UCheb(x,-3.016347e-03,tj,tj1,result);
   UCheb(x,-1.221626e-03,tj,tj1,result);
   UCheb(x,-1.286752e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 7)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n7(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/2.841993e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-2.994677e+00,tj,tj1,result);
   UCheb(x,-2.923264e+00,tj,tj1,result);
   UCheb(x,-6.506190e-01,tj,tj1,result);
   UCheb(x,-1.054280e-01,tj,tj1,result);
   UCheb(x,-1.794587e-02,tj,tj1,result);
   UCheb(x,1.726290e-03,tj,tj1,result);
   UCheb(x,4.534180e-03,tj,tj1,result);
   UCheb(x,4.517845e-03,tj,tj1,result);
   UCheb(x,3.904428e-03,tj,tj1,result);
   UCheb(x,3.882443e-03,tj,tj1,result);
   UCheb(x,3.482988e-03,tj,tj1,result);
   UCheb(x,2.114875e-03,tj,tj1,result);
   UCheb(x,-1.515082e-04,tj,tj1,result);
   UCheb(x,-1.996056e-03,tj,tj1,result);
   UCheb(x,-2.293581e-03,tj,tj1,result);
   UCheb(x,-2.349444e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 8)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n8(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/2.927700e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.155727e+00,tj,tj1,result);
   UCheb(x,-3.135078e+00,tj,tj1,result);
   UCheb(x,-7.247203e-01,tj,tj1,result);
   UCheb(x,-1.309697e-01,tj,tj1,result);
   UCheb(x,-2.993725e-02,tj,tj1,result);
   UCheb(x,-3.567219e-03,tj,tj1,result);
   UCheb(x,3.383704e-03,tj,tj1,result);
   UCheb(x,5.002188e-03,tj,tj1,result);
   UCheb(x,4.487322e-03,tj,tj1,result);
   UCheb(x,3.443899e-03,tj,tj1,result);
   UCheb(x,2.688270e-03,tj,tj1,result);
   UCheb(x,2.600339e-03,tj,tj1,result);
   UCheb(x,1.874948e-03,tj,tj1,result);
   UCheb(x,1.811593e-04,tj,tj1,result);
   UCheb(x,-1.072353e-03,tj,tj1,result);
   UCheb(x,-2.659457e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 9)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n9(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.000000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.298162e+00,tj,tj1,result);
   UCheb(x,-3.325016e+00,tj,tj1,result);
   UCheb(x,-7.939852e-01,tj,tj1,result);
   UCheb(x,-1.563029e-01,tj,tj1,result);
   UCheb(x,-4.222652e-02,tj,tj1,result);
   UCheb(x,-9.195200e-03,tj,tj1,result);
   UCheb(x,1.445665e-03,tj,tj1,result);
   UCheb(x,5.204792e-03,tj,tj1,result);
   UCheb(x,4.775217e-03,tj,tj1,result);
   UCheb(x,3.527781e-03,tj,tj1,result);
   UCheb(x,2.221948e-03,tj,tj1,result);
   UCheb(x,2.242968e-03,tj,tj1,result);
   UCheb(x,2.607959e-03,tj,tj1,result);
   UCheb(x,1.771285e-03,tj,tj1,result);
   UCheb(x,6.694026e-04,tj,tj1,result);
   UCheb(x,-1.481190e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 10)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n10(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.061862e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.425360e+00,tj,tj1,result);
   UCheb(x,-3.496710e+00,tj,tj1,result);
   UCheb(x,-8.587658e-01,tj,tj1,result);
   UCheb(x,-1.812005e-01,tj,tj1,result);
   UCheb(x,-5.427637e-02,tj,tj1,result);
   UCheb(x,-1.515702e-02,tj,tj1,result);
   UCheb(x,-5.406867e-04,tj,tj1,result);
   UCheb(x,4.796295e-03,tj,tj1,result);
   UCheb(x,5.237591e-03,tj,tj1,result);
   UCheb(x,3.654249e-03,tj,tj1,result);
   UCheb(x,2.181165e-03,tj,tj1,result);
   UCheb(x,2.011665e-03,tj,tj1,result);
   UCheb(x,2.417927e-03,tj,tj1,result);
   UCheb(x,2.534880e-03,tj,tj1,result);
   UCheb(x,1.791255e-03,tj,tj1,result);
   UCheb(x,1.871512e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 11)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n11(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.115427e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.539959e+00,tj,tj1,result);
   UCheb(x,-3.652998e+00,tj,tj1,result);
   UCheb(x,-9.196503e-01,tj,tj1,result);
   UCheb(x,-2.054363e-01,tj,tj1,result);
   UCheb(x,-6.618848e-02,tj,tj1,result);
   UCheb(x,-2.109411e-02,tj,tj1,result);
   UCheb(x,-2.786668e-03,tj,tj1,result);
   UCheb(x,4.215648e-03,tj,tj1,result);
   UCheb(x,5.484220e-03,tj,tj1,result);
   UCheb(x,3.935991e-03,tj,tj1,result);
   UCheb(x,2.396191e-03,tj,tj1,result);
   UCheb(x,1.894177e-03,tj,tj1,result);
   UCheb(x,2.206979e-03,tj,tj1,result);
   UCheb(x,2.519055e-03,tj,tj1,result);
   UCheb(x,2.210326e-03,tj,tj1,result);
   UCheb(x,1.189679e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 12)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n12(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.162278e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.644007e+00,tj,tj1,result);
   UCheb(x,-3.796173e+00,tj,tj1,result);
   UCheb(x,-9.771177e-01,tj,tj1,result);
   UCheb(x,-2.290043e-01,tj,tj1,result);
   UCheb(x,-7.794686e-02,tj,tj1,result);
   UCheb(x,-2.702110e-02,tj,tj1,result);
   UCheb(x,-5.185959e-03,tj,tj1,result);
   UCheb(x,3.416259e-03,tj,tj1,result);
   UCheb(x,5.592056e-03,tj,tj1,result);
   UCheb(x,4.201530e-03,tj,tj1,result);
   UCheb(x,2.754365e-03,tj,tj1,result);
   UCheb(x,1.978945e-03,tj,tj1,result);
   UCheb(x,2.012032e-03,tj,tj1,result);
   UCheb(x,2.304579e-03,tj,tj1,result);
   UCheb(x,2.100378e-03,tj,tj1,result);
   UCheb(x,1.728269e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 13)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n13(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.203616e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.739120e+00,tj,tj1,result);
   UCheb(x,-3.928117e+00,tj,tj1,result);
   UCheb(x,-1.031605e+00,tj,tj1,result);
   UCheb(x,-2.519403e-01,tj,tj1,result);
   UCheb(x,-8.962648e-02,tj,tj1,result);
   UCheb(x,-3.292183e-02,tj,tj1,result);
   UCheb(x,-7.809293e-03,tj,tj1,result);
   UCheb(x,2.465156e-03,tj,tj1,result);
   UCheb(x,5.456278e-03,tj,tj1,result);
   UCheb(x,4.446055e-03,tj,tj1,result);
   UCheb(x,3.109490e-03,tj,tj1,result);
   UCheb(x,2.218256e-03,tj,tj1,result);
   UCheb(x,1.941479e-03,tj,tj1,result);
   UCheb(x,2.058603e-03,tj,tj1,result);
   UCheb(x,1.824402e-03,tj,tj1,result);
   UCheb(x,1.830947e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 14)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n14(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.240370e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.826559e+00,tj,tj1,result);
   UCheb(x,-4.050370e+00,tj,tj1,result);
   UCheb(x,-1.083408e+00,tj,tj1,result);
   UCheb(x,-2.743164e-01,tj,tj1,result);
   UCheb(x,-1.012030e-01,tj,tj1,result);
   UCheb(x,-3.884686e-02,tj,tj1,result);
   UCheb(x,-1.059656e-02,tj,tj1,result);
   UCheb(x,1.327521e-03,tj,tj1,result);
   UCheb(x,5.134026e-03,tj,tj1,result);
   UCheb(x,4.584201e-03,tj,tj1,result);
   UCheb(x,3.440618e-03,tj,tj1,result);
   UCheb(x,2.524133e-03,tj,tj1,result);
   UCheb(x,1.990007e-03,tj,tj1,result);
   UCheb(x,1.887334e-03,tj,tj1,result);
   UCheb(x,1.534977e-03,tj,tj1,result);
   UCheb(x,1.705395e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 15)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n15(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.851572e+00,tj,tj1,result);
   UCheb(x,-4.082033e+00,tj,tj1,result);
   UCheb(x,-1.095983e+00,tj,tj1,result);
   UCheb(x,-2.814595e-01,tj,tj1,result);
   UCheb(x,-1.073148e-01,tj,tj1,result);
   UCheb(x,-4.420213e-02,tj,tj1,result);
   UCheb(x,-1.517175e-02,tj,tj1,result);
   UCheb(x,-2.344180e-03,tj,tj1,result);
   UCheb(x,2.371393e-03,tj,tj1,result);
   UCheb(x,2.711443e-03,tj,tj1,result);
   UCheb(x,2.228569e-03,tj,tj1,result);
   UCheb(x,1.683483e-03,tj,tj1,result);
   UCheb(x,1.267112e-03,tj,tj1,result);
   UCheb(x,1.156044e-03,tj,tj1,result);
   UCheb(x,9.131316e-04,tj,tj1,result);
   UCheb(x,1.301023e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 16)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n16(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.852210e+00,tj,tj1,result);
   UCheb(x,-4.077482e+00,tj,tj1,result);
   UCheb(x,-1.091186e+00,tj,tj1,result);
   UCheb(x,-2.797282e-01,tj,tj1,result);
   UCheb(x,-1.084994e-01,tj,tj1,result);
   UCheb(x,-4.667054e-02,tj,tj1,result);
   UCheb(x,-1.843909e-02,tj,tj1,result);
   UCheb(x,-5.456732e-03,tj,tj1,result);
   UCheb(x,-5.039830e-04,tj,tj1,result);
   UCheb(x,4.723508e-04,tj,tj1,result);
   UCheb(x,3.940608e-04,tj,tj1,result);
   UCheb(x,1.478285e-04,tj,tj1,result);
   UCheb(x,-1.649144e-04,tj,tj1,result);
   UCheb(x,-4.237703e-04,tj,tj1,result);
   UCheb(x,-4.707410e-04,tj,tj1,result);
   UCheb(x,-1.874293e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 17)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n17(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.851752e+00,tj,tj1,result);
   UCheb(x,-4.071259e+00,tj,tj1,result);
   UCheb(x,-1.084700e+00,tj,tj1,result);
   UCheb(x,-2.758898e-01,tj,tj1,result);
   UCheb(x,-1.073846e-01,tj,tj1,result);
   UCheb(x,-4.684838e-02,tj,tj1,result);
   UCheb(x,-1.964936e-02,tj,tj1,result);
   UCheb(x,-6.782442e-03,tj,tj1,result);
   UCheb(x,-1.956362e-03,tj,tj1,result);
   UCheb(x,-5.984727e-04,tj,tj1,result);
   UCheb(x,-5.196936e-04,tj,tj1,result);
   UCheb(x,-5.558262e-04,tj,tj1,result);
   UCheb(x,-8.690746e-04,tj,tj1,result);
   UCheb(x,-1.364855e-03,tj,tj1,result);
   UCheb(x,-1.401006e-03,tj,tj1,result);
   UCheb(x,-1.546748e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 18)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n18(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.850840e+00,tj,tj1,result);
   UCheb(x,-4.064799e+00,tj,tj1,result);
   UCheb(x,-1.077651e+00,tj,tj1,result);
   UCheb(x,-2.712659e-01,tj,tj1,result);
   UCheb(x,-1.049217e-01,tj,tj1,result);
   UCheb(x,-4.571333e-02,tj,tj1,result);
   UCheb(x,-1.929809e-02,tj,tj1,result);
   UCheb(x,-6.752044e-03,tj,tj1,result);
   UCheb(x,-1.949464e-03,tj,tj1,result);
   UCheb(x,-3.896101e-04,tj,tj1,result);
   UCheb(x,-4.614460e-05,tj,tj1,result);
   UCheb(x,1.384357e-04,tj,tj1,result);
   UCheb(x,-6.489113e-05,tj,tj1,result);
   UCheb(x,-6.445725e-04,tj,tj1,result);
   UCheb(x,-8.945636e-04,tj,tj1,result);
   UCheb(x,-1.424653e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 19)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n19(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.850027e+00,tj,tj1,result);
   UCheb(x,-4.059159e+00,tj,tj1,result);
   UCheb(x,-1.071106e+00,tj,tj1,result);
   UCheb(x,-2.669960e-01,tj,tj1,result);
   UCheb(x,-1.022780e-01,tj,tj1,result);
   UCheb(x,-4.442555e-02,tj,tj1,result);
   UCheb(x,-1.851335e-02,tj,tj1,result);
   UCheb(x,-6.433865e-03,tj,tj1,result);
   UCheb(x,-1.514465e-03,tj,tj1,result);
   UCheb(x,1.332989e-04,tj,tj1,result);
   UCheb(x,8.606099e-04,tj,tj1,result);
   UCheb(x,1.341945e-03,tj,tj1,result);
   UCheb(x,1.402164e-03,tj,tj1,result);
   UCheb(x,1.039761e-03,tj,tj1,result);
   UCheb(x,5.512831e-04,tj,tj1,result);
   UCheb(x,-3.284427e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 20)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n20(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.849651e+00,tj,tj1,result);
   UCheb(x,-4.054729e+00,tj,tj1,result);
   UCheb(x,-1.065747e+00,tj,tj1,result);
   UCheb(x,-2.636243e-01,tj,tj1,result);
   UCheb(x,-1.003234e-01,tj,tj1,result);
   UCheb(x,-4.372789e-02,tj,tj1,result);
   UCheb(x,-1.831551e-02,tj,tj1,result);
   UCheb(x,-6.763090e-03,tj,tj1,result);
   UCheb(x,-1.830626e-03,tj,tj1,result);
   UCheb(x,-2.122384e-04,tj,tj1,result);
   UCheb(x,8.108328e-04,tj,tj1,result);
   UCheb(x,1.557983e-03,tj,tj1,result);
   UCheb(x,1.945666e-03,tj,tj1,result);
   UCheb(x,1.965696e-03,tj,tj1,result);
   UCheb(x,1.493236e-03,tj,tj1,result);
   UCheb(x,1.162591e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 21)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n21(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.849649e+00,tj,tj1,result);
   UCheb(x,-4.051155e+00,tj,tj1,result);
   UCheb(x,-1.061430e+00,tj,tj1,result);
   UCheb(x,-2.608869e-01,tj,tj1,result);
   UCheb(x,-9.902788e-02,tj,tj1,result);
   UCheb(x,-4.346562e-02,tj,tj1,result);
   UCheb(x,-1.874709e-02,tj,tj1,result);
   UCheb(x,-7.682887e-03,tj,tj1,result);
   UCheb(x,-3.026206e-03,tj,tj1,result);
   UCheb(x,-1.534551e-03,tj,tj1,result);
   UCheb(x,-4.990575e-04,tj,tj1,result);
   UCheb(x,3.713334e-04,tj,tj1,result);
   UCheb(x,9.737011e-04,tj,tj1,result);
   UCheb(x,1.304571e-03,tj,tj1,result);
   UCheb(x,1.133110e-03,tj,tj1,result);
   UCheb(x,1.123457e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 22)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n22(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.849598e+00,tj,tj1,result);
   UCheb(x,-4.047605e+00,tj,tj1,result);
   UCheb(x,-1.057264e+00,tj,tj1,result);
   UCheb(x,-2.579513e-01,tj,tj1,result);
   UCheb(x,-9.749602e-02,tj,tj1,result);
   UCheb(x,-4.275137e-02,tj,tj1,result);
   UCheb(x,-1.881768e-02,tj,tj1,result);
   UCheb(x,-8.177374e-03,tj,tj1,result);
   UCheb(x,-3.981056e-03,tj,tj1,result);
   UCheb(x,-2.696290e-03,tj,tj1,result);
   UCheb(x,-1.886803e-03,tj,tj1,result);
   UCheb(x,-1.085378e-03,tj,tj1,result);
   UCheb(x,-4.675242e-04,tj,tj1,result);
   UCheb(x,-5.426367e-05,tj,tj1,result);
   UCheb(x,1.039613e-04,tj,tj1,result);
   UCheb(x,2.662378e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 23)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n23(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.849269e+00,tj,tj1,result);
   UCheb(x,-4.043761e+00,tj,tj1,result);
   UCheb(x,-1.052735e+00,tj,tj1,result);
   UCheb(x,-2.544683e-01,tj,tj1,result);
   UCheb(x,-9.517503e-02,tj,tj1,result);
   UCheb(x,-4.112082e-02,tj,tj1,result);
   UCheb(x,-1.782070e-02,tj,tj1,result);
   UCheb(x,-7.549483e-03,tj,tj1,result);
   UCheb(x,-3.747329e-03,tj,tj1,result);
   UCheb(x,-2.694263e-03,tj,tj1,result);
   UCheb(x,-2.147141e-03,tj,tj1,result);
   UCheb(x,-1.526209e-03,tj,tj1,result);
   UCheb(x,-1.039173e-03,tj,tj1,result);
   UCheb(x,-7.235615e-04,tj,tj1,result);
   UCheb(x,-4.656546e-04,tj,tj1,result);
   UCheb(x,-3.014423e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 24)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n24(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.848925e+00,tj,tj1,result);
   UCheb(x,-4.040178e+00,tj,tj1,result);
   UCheb(x,-1.048355e+00,tj,tj1,result);
   UCheb(x,-2.510198e-01,tj,tj1,result);
   UCheb(x,-9.261134e-02,tj,tj1,result);
   UCheb(x,-3.915864e-02,tj,tj1,result);
   UCheb(x,-1.627423e-02,tj,tj1,result);
   UCheb(x,-6.307345e-03,tj,tj1,result);
   UCheb(x,-2.732992e-03,tj,tj1,result);
   UCheb(x,-1.869652e-03,tj,tj1,result);
   UCheb(x,-1.494176e-03,tj,tj1,result);
   UCheb(x,-1.047533e-03,tj,tj1,result);
   UCheb(x,-7.178439e-04,tj,tj1,result);
   UCheb(x,-5.424171e-04,tj,tj1,result);
   UCheb(x,-3.829195e-04,tj,tj1,result);
   UCheb(x,-2.840810e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 25)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n25(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.848937e+00,tj,tj1,result);
   UCheb(x,-4.037512e+00,tj,tj1,result);
   UCheb(x,-1.044866e+00,tj,tj1,result);
   UCheb(x,-2.483269e-01,tj,tj1,result);
   UCheb(x,-9.063682e-02,tj,tj1,result);
   UCheb(x,-3.767778e-02,tj,tj1,result);
   UCheb(x,-1.508540e-02,tj,tj1,result);
   UCheb(x,-5.332756e-03,tj,tj1,result);
   UCheb(x,-1.881511e-03,tj,tj1,result);
   UCheb(x,-1.124041e-03,tj,tj1,result);
   UCheb(x,-8.368456e-04,tj,tj1,result);
   UCheb(x,-4.930499e-04,tj,tj1,result);
   UCheb(x,-2.779630e-04,tj,tj1,result);
   UCheb(x,-2.029528e-04,tj,tj1,result);
   UCheb(x,-1.658678e-04,tj,tj1,result);
   UCheb(x,-1.289695e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 26)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n26(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.849416e+00,tj,tj1,result);
   UCheb(x,-4.035915e+00,tj,tj1,result);
   UCheb(x,-1.042493e+00,tj,tj1,result);
   UCheb(x,-2.466021e-01,tj,tj1,result);
   UCheb(x,-8.956432e-02,tj,tj1,result);
   UCheb(x,-3.698914e-02,tj,tj1,result);
   UCheb(x,-1.465689e-02,tj,tj1,result);
   UCheb(x,-5.035254e-03,tj,tj1,result);
   UCheb(x,-1.674614e-03,tj,tj1,result);
   UCheb(x,-9.492734e-04,tj,tj1,result);
   UCheb(x,-7.014021e-04,tj,tj1,result);
   UCheb(x,-3.944953e-04,tj,tj1,result);
   UCheb(x,-2.255750e-04,tj,tj1,result);
   UCheb(x,-2.075841e-04,tj,tj1,result);
   UCheb(x,-1.989330e-04,tj,tj1,result);
   UCheb(x,-2.134862e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 27)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n27(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.850070e+00,tj,tj1,result);
   UCheb(x,-4.034815e+00,tj,tj1,result);
   UCheb(x,-1.040650e+00,tj,tj1,result);
   UCheb(x,-2.453117e-01,tj,tj1,result);
   UCheb(x,-8.886426e-02,tj,tj1,result);
   UCheb(x,-3.661702e-02,tj,tj1,result);
   UCheb(x,-1.452346e-02,tj,tj1,result);
   UCheb(x,-5.002476e-03,tj,tj1,result);
   UCheb(x,-1.720126e-03,tj,tj1,result);
   UCheb(x,-1.001400e-03,tj,tj1,result);
   UCheb(x,-7.729826e-04,tj,tj1,result);
   UCheb(x,-4.740640e-04,tj,tj1,result);
   UCheb(x,-3.206333e-04,tj,tj1,result);
   UCheb(x,-3.366093e-04,tj,tj1,result);
   UCheb(x,-3.193471e-04,tj,tj1,result);
   UCheb(x,-3.804091e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 28)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n28(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.850668e+00,tj,tj1,result);
   UCheb(x,-4.033786e+00,tj,tj1,result);
   UCheb(x,-1.038853e+00,tj,tj1,result);
   UCheb(x,-2.440281e-01,tj,tj1,result);
   UCheb(x,-8.806020e-02,tj,tj1,result);
   UCheb(x,-3.612883e-02,tj,tj1,result);
   UCheb(x,-1.420436e-02,tj,tj1,result);
   UCheb(x,-4.787982e-03,tj,tj1,result);
   UCheb(x,-1.535230e-03,tj,tj1,result);
   UCheb(x,-8.263121e-04,tj,tj1,result);
   UCheb(x,-5.849609e-04,tj,tj1,result);
   UCheb(x,-2.863967e-04,tj,tj1,result);
   UCheb(x,-1.391610e-04,tj,tj1,result);
   UCheb(x,-1.720294e-04,tj,tj1,result);
   UCheb(x,-1.952273e-04,tj,tj1,result);
   UCheb(x,-2.901413e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 29)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n29(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.851217e+00,tj,tj1,result);
   UCheb(x,-4.032834e+00,tj,tj1,result);
   UCheb(x,-1.037113e+00,tj,tj1,result);
   UCheb(x,-2.427762e-01,tj,tj1,result);
   UCheb(x,-8.719146e-02,tj,tj1,result);
   UCheb(x,-3.557172e-02,tj,tj1,result);
   UCheb(x,-1.375498e-02,tj,tj1,result);
   UCheb(x,-4.452033e-03,tj,tj1,result);
   UCheb(x,-1.187516e-03,tj,tj1,result);
   UCheb(x,-4.916936e-04,tj,tj1,result);
   UCheb(x,-2.065533e-04,tj,tj1,result);
   UCheb(x,1.067301e-04,tj,tj1,result);
   UCheb(x,2.615824e-04,tj,tj1,result);
   UCheb(x,2.432244e-04,tj,tj1,result);
   UCheb(x,1.417795e-04,tj,tj1,result);
   UCheb(x,4.710038e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 30)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n30(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.851845e+00,tj,tj1,result);
   UCheb(x,-4.032148e+00,tj,tj1,result);
   UCheb(x,-1.035679e+00,tj,tj1,result);
   UCheb(x,-2.417758e-01,tj,tj1,result);
   UCheb(x,-8.655330e-02,tj,tj1,result);
   UCheb(x,-3.522132e-02,tj,tj1,result);
   UCheb(x,-1.352106e-02,tj,tj1,result);
   UCheb(x,-4.326911e-03,tj,tj1,result);
   UCheb(x,-1.064969e-03,tj,tj1,result);
   UCheb(x,-3.813321e-04,tj,tj1,result);
   UCheb(x,-5.683881e-05,tj,tj1,result);
   UCheb(x,2.813346e-04,tj,tj1,result);
   UCheb(x,4.627085e-04,tj,tj1,result);
   UCheb(x,4.832107e-04,tj,tj1,result);
   UCheb(x,3.519336e-04,tj,tj1,result);
   UCheb(x,2.888530e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 5, 100)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln5n100(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.250000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.877940e+00,tj,tj1,result);
   UCheb(x,-4.039324e+00,tj,tj1,result);
   UCheb(x,-1.022243e+00,tj,tj1,result);
   UCheb(x,-2.305825e-01,tj,tj1,result);
   UCheb(x,-7.960119e-02,tj,tj1,result);
   UCheb(x,-3.112000e-02,tj,tj1,result);
   UCheb(x,-1.138868e-02,tj,tj1,result);
   UCheb(x,-3.418164e-03,tj,tj1,result);
   UCheb(x,-9.174520e-04,tj,tj1,result);
   UCheb(x,-5.489617e-04,tj,tj1,result);
   UCheb(x,-3.878301e-04,tj,tj1,result);
   UCheb(x,-1.302233e-04,tj,tj1,result);
   UCheb(x,1.054113e-05,tj,tj1,result);
   UCheb(x,2.458862e-05,tj,tj1,result);
   UCheb(x,-4.186591e-06,tj,tj1,result);
   UCheb(x,-2.623412e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 6, 6)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln6n6(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/2.882307e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.054075e+00,tj,tj1,result);
   UCheb(x,-2.998804e+00,tj,tj1,result);
   UCheb(x,-6.681518e-01,tj,tj1,result);
   UCheb(x,-1.067578e-01,tj,tj1,result);
   UCheb(x,-1.709435e-02,tj,tj1,result);
   UCheb(x,9.952661e-04,tj,tj1,result);
   UCheb(x,3.641700e-03,tj,tj1,result);
   UCheb(x,2.304572e-03,tj,tj1,result);
   UCheb(x,3.336275e-03,tj,tj1,result);
   UCheb(x,4.770385e-03,tj,tj1,result);
   UCheb(x,5.401891e-03,tj,tj1,result);
   UCheb(x,2.246148e-03,tj,tj1,result);
   UCheb(x,-1.442663e-03,tj,tj1,result);
   UCheb(x,-2.502866e-03,tj,tj1,result);
   UCheb(x,-2.105855e-03,tj,tj1,result);
   UCheb(x,-4.739371e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 6, 7)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln6n7(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.000000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.265287e+00,tj,tj1,result);
   UCheb(x,-3.274613e+00,tj,tj1,result);
   UCheb(x,-7.582352e-01,tj,tj1,result);
   UCheb(x,-1.334293e-01,tj,tj1,result);
   UCheb(x,-2.915502e-02,tj,tj1,result);
   UCheb(x,-4.108091e-03,tj,tj1,result);
   UCheb(x,1.546701e-03,tj,tj1,result);
   UCheb(x,2.298827e-03,tj,tj1,result);
   UCheb(x,2.891501e-03,tj,tj1,result);
   UCheb(x,4.313717e-03,tj,tj1,result);
   UCheb(x,4.989501e-03,tj,tj1,result);
   UCheb(x,3.914594e-03,tj,tj1,result);
   UCheb(x,1.062372e-03,tj,tj1,result);
   UCheb(x,-1.158841e-03,tj,tj1,result);
   UCheb(x,-1.596443e-03,tj,tj1,result);
   UCheb(x,-1.185662e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 6, 8)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln6n8(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.098387e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.450954e+00,tj,tj1,result);
   UCheb(x,-3.520462e+00,tj,tj1,result);
   UCheb(x,-8.420299e-01,tj,tj1,result);
   UCheb(x,-1.604853e-01,tj,tj1,result);
   UCheb(x,-4.165840e-02,tj,tj1,result);
   UCheb(x,-1.008756e-02,tj,tj1,result);
   UCheb(x,-6.723402e-04,tj,tj1,result);
   UCheb(x,1.843521e-03,tj,tj1,result);
   UCheb(x,2.883405e-03,tj,tj1,result);
   UCheb(x,3.720980e-03,tj,tj1,result);
   UCheb(x,4.301709e-03,tj,tj1,result);
   UCheb(x,3.948034e-03,tj,tj1,result);
   UCheb(x,2.776243e-03,tj,tj1,result);
   UCheb(x,8.623736e-04,tj,tj1,result);
   UCheb(x,-3.742068e-04,tj,tj1,result);
   UCheb(x,-9.796927e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 6, 9)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln6n9(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.181981e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.616113e+00,tj,tj1,result);
   UCheb(x,-3.741650e+00,tj,tj1,result);
   UCheb(x,-9.204487e-01,tj,tj1,result);
   UCheb(x,-1.873068e-01,tj,tj1,result);
   UCheb(x,-5.446794e-02,tj,tj1,result);
   UCheb(x,-1.632286e-02,tj,tj1,result);
   UCheb(x,-3.266481e-03,tj,tj1,result);
   UCheb(x,1.280067e-03,tj,tj1,result);
   UCheb(x,2.780687e-03,tj,tj1,result);
   UCheb(x,3.480242e-03,tj,tj1,result);
   UCheb(x,3.592200e-03,tj,tj1,result);
   UCheb(x,3.581019e-03,tj,tj1,result);
   UCheb(x,3.264231e-03,tj,tj1,result);
   UCheb(x,2.347174e-03,tj,tj1,result);
   UCheb(x,1.167535e-03,tj,tj1,result);
   UCheb(x,-1.092185e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 6, 10)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln6n10(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.253957e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.764382e+00,tj,tj1,result);
   UCheb(x,-3.942366e+00,tj,tj1,result);
   UCheb(x,-9.939896e-01,tj,tj1,result);
   UCheb(x,-2.137812e-01,tj,tj1,result);
   UCheb(x,-6.720270e-02,tj,tj1,result);
   UCheb(x,-2.281070e-02,tj,tj1,result);
   UCheb(x,-5.901060e-03,tj,tj1,result);
   UCheb(x,3.824937e-04,tj,tj1,result);
   UCheb(x,2.802812e-03,tj,tj1,result);
   UCheb(x,3.258132e-03,tj,tj1,result);
   UCheb(x,3.233536e-03,tj,tj1,result);
   UCheb(x,3.085530e-03,tj,tj1,result);
   UCheb(x,3.212151e-03,tj,tj1,result);
   UCheb(x,3.001329e-03,tj,tj1,result);
   UCheb(x,2.226048e-03,tj,tj1,result);
   UCheb(x,1.035298e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 6, 11)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln6n11(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.316625e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.898597e+00,tj,tj1,result);
   UCheb(x,-4.125710e+00,tj,tj1,result);
   UCheb(x,-1.063297e+00,tj,tj1,result);
   UCheb(x,-2.396852e-01,tj,tj1,result);
   UCheb(x,-7.990126e-02,tj,tj1,result);
   UCheb(x,-2.927977e-02,tj,tj1,result);
   UCheb(x,-8.726500e-03,tj,tj1,result);
   UCheb(x,-5.858745e-04,tj,tj1,result);
   UCheb(x,2.654590e-03,tj,tj1,result);
   UCheb(x,3.217736e-03,tj,tj1,result);
   UCheb(x,2.989770e-03,tj,tj1,result);
   UCheb(x,2.768493e-03,tj,tj1,result);
   UCheb(x,2.924364e-03,tj,tj1,result);
   UCheb(x,3.140215e-03,tj,tj1,result);
   UCheb(x,2.647914e-03,tj,tj1,result);
   UCheb(x,1.924802e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 6, 12)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln6n12(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.371709e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.020941e+00,tj,tj1,result);
   UCheb(x,-4.294250e+00,tj,tj1,result);
   UCheb(x,-1.128842e+00,tj,tj1,result);
   UCheb(x,-2.650389e-01,tj,tj1,result);
   UCheb(x,-9.248611e-02,tj,tj1,result);
   UCheb(x,-3.578510e-02,tj,tj1,result);
   UCheb(x,-1.162852e-02,tj,tj1,result);
   UCheb(x,-1.746982e-03,tj,tj1,result);
   UCheb(x,2.454209e-03,tj,tj1,result);
   UCheb(x,3.128042e-03,tj,tj1,result);
   UCheb(x,2.936650e-03,tj,tj1,result);
   UCheb(x,2.530794e-03,tj,tj1,result);
   UCheb(x,2.665192e-03,tj,tj1,result);
   UCheb(x,2.994144e-03,tj,tj1,result);
   UCheb(x,2.662249e-03,tj,tj1,result);
   UCheb(x,2.368541e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 6, 13)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln6n13(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.420526e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.133167e+00,tj,tj1,result);
   UCheb(x,-4.450016e+00,tj,tj1,result);
   UCheb(x,-1.191088e+00,tj,tj1,result);
   UCheb(x,-2.898220e-01,tj,tj1,result);
   UCheb(x,-1.050249e-01,tj,tj1,result);
   UCheb(x,-4.226901e-02,tj,tj1,result);
   UCheb(x,-1.471113e-02,tj,tj1,result);
   UCheb(x,-3.007470e-03,tj,tj1,result);
   UCheb(x,2.049420e-03,tj,tj1,result);
   UCheb(x,3.059074e-03,tj,tj1,result);
   UCheb(x,2.881249e-03,tj,tj1,result);
   UCheb(x,2.452780e-03,tj,tj1,result);
   UCheb(x,2.441805e-03,tj,tj1,result);
   UCheb(x,2.787493e-03,tj,tj1,result);
   UCheb(x,2.483957e-03,tj,tj1,result);
   UCheb(x,2.481590e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 6, 14)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln6n14(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.450000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.201268e+00,tj,tj1,result);
   UCheb(x,-4.542568e+00,tj,tj1,result);
   UCheb(x,-1.226965e+00,tj,tj1,result);
   UCheb(x,-3.046029e-01,tj,tj1,result);
   UCheb(x,-1.136657e-01,tj,tj1,result);
   UCheb(x,-4.786757e-02,tj,tj1,result);
   UCheb(x,-1.843748e-02,tj,tj1,result);
   UCheb(x,-5.588022e-03,tj,tj1,result);
   UCheb(x,2.253029e-04,tj,tj1,result);
   UCheb(x,1.667188e-03,tj,tj1,result);
   UCheb(x,1.788330e-03,tj,tj1,result);
   UCheb(x,1.474545e-03,tj,tj1,result);
   UCheb(x,1.540494e-03,tj,tj1,result);
   UCheb(x,1.951188e-03,tj,tj1,result);
   UCheb(x,1.863323e-03,tj,tj1,result);
   UCheb(x,2.220904e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 6, 15)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln6n15(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.450000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.195689e+00,tj,tj1,result);
   UCheb(x,-4.526567e+00,tj,tj1,result);
   UCheb(x,-1.213617e+00,tj,tj1,result);
   UCheb(x,-2.975035e-01,tj,tj1,result);
   UCheb(x,-1.118480e-01,tj,tj1,result);
   UCheb(x,-4.859142e-02,tj,tj1,result);
   UCheb(x,-2.083312e-02,tj,tj1,result);
   UCheb(x,-8.298720e-03,tj,tj1,result);
   UCheb(x,-2.766708e-03,tj,tj1,result);
   UCheb(x,-1.026356e-03,tj,tj1,result);
   UCheb(x,-9.093113e-04,tj,tj1,result);
   UCheb(x,-1.135168e-03,tj,tj1,result);
   UCheb(x,-1.136376e-03,tj,tj1,result);
   UCheb(x,-8.190870e-04,tj,tj1,result);
   UCheb(x,-4.435972e-04,tj,tj1,result);
   UCheb(x,1.413129e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 6, 30)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln6n30(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.450000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.166269e+00,tj,tj1,result);
   UCheb(x,-4.427399e+00,tj,tj1,result);
   UCheb(x,-1.118239e+00,tj,tj1,result);
   UCheb(x,-2.360847e-01,tj,tj1,result);
   UCheb(x,-7.745885e-02,tj,tj1,result);
   UCheb(x,-3.025041e-02,tj,tj1,result);
   UCheb(x,-1.187179e-02,tj,tj1,result);
   UCheb(x,-4.432089e-03,tj,tj1,result);
   UCheb(x,-1.408451e-03,tj,tj1,result);
   UCheb(x,-4.388774e-04,tj,tj1,result);
   UCheb(x,-2.795560e-04,tj,tj1,result);
   UCheb(x,-2.304136e-04,tj,tj1,result);
   UCheb(x,-1.258516e-04,tj,tj1,result);
   UCheb(x,-4.180236e-05,tj,tj1,result);
   UCheb(x,-4.388679e-06,tj,tj1,result);
   UCheb(x,4.836027e-06,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 6, 100)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln6n100(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.450000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.181350e+00,tj,tj1,result);
   UCheb(x,-4.417919e+00,tj,tj1,result);
   UCheb(x,-1.094201e+00,tj,tj1,result);
   UCheb(x,-2.195883e-01,tj,tj1,result);
   UCheb(x,-6.818937e-02,tj,tj1,result);
   UCheb(x,-2.514202e-02,tj,tj1,result);
   UCheb(x,-9.125047e-03,tj,tj1,result);
   UCheb(x,-3.022148e-03,tj,tj1,result);
   UCheb(x,-7.284181e-04,tj,tj1,result);
   UCheb(x,-1.157766e-04,tj,tj1,result);
   UCheb(x,-1.023752e-04,tj,tj1,result);
   UCheb(x,-1.127985e-04,tj,tj1,result);
   UCheb(x,-5.221690e-05,tj,tj1,result);
   UCheb(x,-3.516179e-06,tj,tj1,result);
   UCheb(x,9.501398e-06,tj,tj1,result);
   UCheb(x,9.380220e-06,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 7, 7)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln7n7(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.130495e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.501264e+00,tj,tj1,result);
   UCheb(x,-3.584790e+00,tj,tj1,result);
   UCheb(x,-8.577311e-01,tj,tj1,result);
   UCheb(x,-1.617002e-01,tj,tj1,result);
   UCheb(x,-4.145186e-02,tj,tj1,result);
   UCheb(x,-1.023462e-02,tj,tj1,result);
   UCheb(x,-1.408251e-03,tj,tj1,result);
   UCheb(x,8.626515e-04,tj,tj1,result);
   UCheb(x,2.072492e-03,tj,tj1,result);
   UCheb(x,3.722926e-03,tj,tj1,result);
   UCheb(x,5.095445e-03,tj,tj1,result);
   UCheb(x,4.842602e-03,tj,tj1,result);
   UCheb(x,2.751427e-03,tj,tj1,result);
   UCheb(x,2.008927e-04,tj,tj1,result);
   UCheb(x,-9.892431e-04,tj,tj1,result);
   UCheb(x,-8.772386e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 7, 8)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln7n8(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.240370e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.709965e+00,tj,tj1,result);
   UCheb(x,-3.862154e+00,tj,tj1,result);
   UCheb(x,-9.504541e-01,tj,tj1,result);
   UCheb(x,-1.900195e-01,tj,tj1,result);
   UCheb(x,-5.439995e-02,tj,tj1,result);
   UCheb(x,-1.678028e-02,tj,tj1,result);
   UCheb(x,-4.485540e-03,tj,tj1,result);
   UCheb(x,-4.437047e-04,tj,tj1,result);
   UCheb(x,1.440092e-03,tj,tj1,result);
   UCheb(x,3.114227e-03,tj,tj1,result);
   UCheb(x,4.516569e-03,tj,tj1,result);
   UCheb(x,4.829457e-03,tj,tj1,result);
   UCheb(x,3.787550e-03,tj,tj1,result);
   UCheb(x,1.761866e-03,tj,tj1,result);
   UCheb(x,1.991911e-04,tj,tj1,result);
   UCheb(x,-4.533481e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 7, 9)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln7n9(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.334314e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.896550e+00,tj,tj1,result);
   UCheb(x,-4.112671e+00,tj,tj1,result);
   UCheb(x,-1.037277e+00,tj,tj1,result);
   UCheb(x,-2.181695e-01,tj,tj1,result);
   UCheb(x,-6.765190e-02,tj,tj1,result);
   UCheb(x,-2.360116e-02,tj,tj1,result);
   UCheb(x,-7.695960e-03,tj,tj1,result);
   UCheb(x,-1.780578e-03,tj,tj1,result);
   UCheb(x,8.963843e-04,tj,tj1,result);
   UCheb(x,2.616148e-03,tj,tj1,result);
   UCheb(x,3.852104e-03,tj,tj1,result);
   UCheb(x,4.390744e-03,tj,tj1,result);
   UCheb(x,4.014041e-03,tj,tj1,result);
   UCheb(x,2.888101e-03,tj,tj1,result);
   UCheb(x,1.467474e-03,tj,tj1,result);
   UCheb(x,4.004611e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 7, 10)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln7n10(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.415650e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.064844e+00,tj,tj1,result);
   UCheb(x,-4.340749e+00,tj,tj1,result);
   UCheb(x,-1.118888e+00,tj,tj1,result);
   UCheb(x,-2.459730e-01,tj,tj1,result);
   UCheb(x,-8.097781e-02,tj,tj1,result);
   UCheb(x,-3.057688e-02,tj,tj1,result);
   UCheb(x,-1.097406e-02,tj,tj1,result);
   UCheb(x,-3.209262e-03,tj,tj1,result);
   UCheb(x,4.065641e-04,tj,tj1,result);
   UCheb(x,2.196677e-03,tj,tj1,result);
   UCheb(x,3.313994e-03,tj,tj1,result);
   UCheb(x,3.827157e-03,tj,tj1,result);
   UCheb(x,3.822284e-03,tj,tj1,result);
   UCheb(x,3.389090e-03,tj,tj1,result);
   UCheb(x,2.340850e-03,tj,tj1,result);
   UCheb(x,1.395172e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 7, 11)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln7n11(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.486817e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.217795e+00,tj,tj1,result);
   UCheb(x,-4.549783e+00,tj,tj1,result);
   UCheb(x,-1.195905e+00,tj,tj1,result);
   UCheb(x,-2.733093e-01,tj,tj1,result);
   UCheb(x,-9.428447e-02,tj,tj1,result);
   UCheb(x,-3.760093e-02,tj,tj1,result);
   UCheb(x,-1.431676e-02,tj,tj1,result);
   UCheb(x,-4.717152e-03,tj,tj1,result);
   UCheb(x,-1.032199e-04,tj,tj1,result);
   UCheb(x,1.832423e-03,tj,tj1,result);
   UCheb(x,2.905979e-03,tj,tj1,result);
   UCheb(x,3.302799e-03,tj,tj1,result);
   UCheb(x,3.464371e-03,tj,tj1,result);
   UCheb(x,3.456211e-03,tj,tj1,result);
   UCheb(x,2.736244e-03,tj,tj1,result);
   UCheb(x,2.140712e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 7, 12)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln7n12(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.500000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.235822e+00,tj,tj1,result);
   UCheb(x,-4.564100e+00,tj,tj1,result);
   UCheb(x,-1.190813e+00,tj,tj1,result);
   UCheb(x,-2.686546e-01,tj,tj1,result);
   UCheb(x,-9.395083e-02,tj,tj1,result);
   UCheb(x,-3.967359e-02,tj,tj1,result);
   UCheb(x,-1.747096e-02,tj,tj1,result);
   UCheb(x,-8.304144e-03,tj,tj1,result);
   UCheb(x,-3.903198e-03,tj,tj1,result);
   UCheb(x,-2.134906e-03,tj,tj1,result);
   UCheb(x,-1.175035e-03,tj,tj1,result);
   UCheb(x,-7.266224e-04,tj,tj1,result);
   UCheb(x,-1.892931e-04,tj,tj1,result);
   UCheb(x,5.604706e-04,tj,tj1,result);
   UCheb(x,9.070459e-04,tj,tj1,result);
   UCheb(x,1.427010e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 7, 13)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln7n13(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.500000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.222204e+00,tj,tj1,result);
   UCheb(x,-4.532300e+00,tj,tj1,result);
   UCheb(x,-1.164642e+00,tj,tj1,result);
   UCheb(x,-2.523768e-01,tj,tj1,result);
   UCheb(x,-8.531984e-02,tj,tj1,result);
   UCheb(x,-3.467857e-02,tj,tj1,result);
   UCheb(x,-1.483804e-02,tj,tj1,result);
   UCheb(x,-6.524136e-03,tj,tj1,result);
   UCheb(x,-3.077740e-03,tj,tj1,result);
   UCheb(x,-1.745218e-03,tj,tj1,result);
   UCheb(x,-1.602085e-03,tj,tj1,result);
   UCheb(x,-1.828831e-03,tj,tj1,result);
   UCheb(x,-1.994070e-03,tj,tj1,result);
   UCheb(x,-1.873879e-03,tj,tj1,result);
   UCheb(x,-1.341937e-03,tj,tj1,result);
   UCheb(x,-8.706444e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 7, 14)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln7n14(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.500000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.211763e+00,tj,tj1,result);
   UCheb(x,-4.507542e+00,tj,tj1,result);
   UCheb(x,-1.143640e+00,tj,tj1,result);
   UCheb(x,-2.395755e-01,tj,tj1,result);
   UCheb(x,-7.808020e-02,tj,tj1,result);
   UCheb(x,-3.044259e-02,tj,tj1,result);
   UCheb(x,-1.182308e-02,tj,tj1,result);
   UCheb(x,-4.057325e-03,tj,tj1,result);
   UCheb(x,-5.724255e-04,tj,tj1,result);
   UCheb(x,8.303900e-04,tj,tj1,result);
   UCheb(x,1.113148e-03,tj,tj1,result);
   UCheb(x,8.102514e-04,tj,tj1,result);
   UCheb(x,3.559442e-04,tj,tj1,result);
   UCheb(x,4.634986e-05,tj,tj1,result);
   UCheb(x,-8.776476e-05,tj,tj1,result);
   UCheb(x,1.054489e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 7, 15)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln7n15(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.500000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.204898e+00,tj,tj1,result);
   UCheb(x,-4.489960e+00,tj,tj1,result);
   UCheb(x,-1.129172e+00,tj,tj1,result);
   UCheb(x,-2.316741e-01,tj,tj1,result);
   UCheb(x,-7.506107e-02,tj,tj1,result);
   UCheb(x,-2.983676e-02,tj,tj1,result);
   UCheb(x,-1.258013e-02,tj,tj1,result);
   UCheb(x,-5.262515e-03,tj,tj1,result);
   UCheb(x,-1.984156e-03,tj,tj1,result);
   UCheb(x,-3.912108e-04,tj,tj1,result);
   UCheb(x,8.974023e-05,tj,tj1,result);
   UCheb(x,6.056195e-05,tj,tj1,result);
   UCheb(x,-2.090842e-04,tj,tj1,result);
   UCheb(x,-5.232620e-04,tj,tj1,result);
   UCheb(x,-5.816339e-04,tj,tj1,result);
   UCheb(x,-7.020421e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 7, 30)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln7n30(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.500000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.176536e+00,tj,tj1,result);
   UCheb(x,-4.398705e+00,tj,tj1,result);
   UCheb(x,-1.045481e+00,tj,tj1,result);
   UCheb(x,-1.821982e-01,tj,tj1,result);
   UCheb(x,-4.962304e-02,tj,tj1,result);
   UCheb(x,-1.698132e-02,tj,tj1,result);
   UCheb(x,-6.062667e-03,tj,tj1,result);
   UCheb(x,-2.282353e-03,tj,tj1,result);
   UCheb(x,-8.014836e-04,tj,tj1,result);
   UCheb(x,-2.035683e-04,tj,tj1,result);
   UCheb(x,-1.004137e-05,tj,tj1,result);
   UCheb(x,3.801453e-06,tj,tj1,result);
   UCheb(x,-1.920705e-05,tj,tj1,result);
   UCheb(x,-2.518735e-05,tj,tj1,result);
   UCheb(x,-1.821501e-05,tj,tj1,result);
   UCheb(x,-1.801008e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 7, 100)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln7n100(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.500000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.188337e+00,tj,tj1,result);
   UCheb(x,-4.386949e+00,tj,tj1,result);
   UCheb(x,-1.022834e+00,tj,tj1,result);
   UCheb(x,-1.686517e-01,tj,tj1,result);
   UCheb(x,-4.323516e-02,tj,tj1,result);
   UCheb(x,-1.399392e-02,tj,tj1,result);
   UCheb(x,-4.644333e-03,tj,tj1,result);
   UCheb(x,-1.617044e-03,tj,tj1,result);
   UCheb(x,-5.031396e-04,tj,tj1,result);
   UCheb(x,-8.792066e-05,tj,tj1,result);
   UCheb(x,2.675457e-05,tj,tj1,result);
   UCheb(x,1.673416e-05,tj,tj1,result);
   UCheb(x,-6.258552e-06,tj,tj1,result);
   UCheb(x,-8.174214e-06,tj,tj1,result);
   UCheb(x,-3.073644e-06,tj,tj1,result);
   UCheb(x,-1.349958e-06,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 8, 8)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln8n8(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.360672e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-3.940217e+00,tj,tj1,result);
   UCheb(x,-4.168913e+00,tj,tj1,result);
   UCheb(x,-1.051485e+00,tj,tj1,result);
   UCheb(x,-2.195325e-01,tj,tj1,result);
   UCheb(x,-6.775196e-02,tj,tj1,result);
   UCheb(x,-2.385506e-02,tj,tj1,result);
   UCheb(x,-8.244902e-03,tj,tj1,result);
   UCheb(x,-2.525632e-03,tj,tj1,result);
   UCheb(x,2.771275e-04,tj,tj1,result);
   UCheb(x,2.332874e-03,tj,tj1,result);
   UCheb(x,4.079599e-03,tj,tj1,result);
   UCheb(x,4.882551e-03,tj,tj1,result);
   UCheb(x,4.407944e-03,tj,tj1,result);
   UCheb(x,2.769844e-03,tj,tj1,result);
   UCheb(x,1.062433e-03,tj,tj1,result);
   UCheb(x,5.872535e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 8, 9)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln8n9(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.464102e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.147004e+00,tj,tj1,result);
   UCheb(x,-4.446939e+00,tj,tj1,result);
   UCheb(x,-1.146155e+00,tj,tj1,result);
   UCheb(x,-2.488561e-01,tj,tj1,result);
   UCheb(x,-8.144561e-02,tj,tj1,result);
   UCheb(x,-3.116917e-02,tj,tj1,result);
   UCheb(x,-1.205667e-02,tj,tj1,result);
   UCheb(x,-4.515661e-03,tj,tj1,result);
   UCheb(x,-7.618616e-04,tj,tj1,result);
   UCheb(x,1.599011e-03,tj,tj1,result);
   UCheb(x,3.457324e-03,tj,tj1,result);
   UCheb(x,4.482917e-03,tj,tj1,result);
   UCheb(x,4.488267e-03,tj,tj1,result);
   UCheb(x,3.469823e-03,tj,tj1,result);
   UCheb(x,1.957591e-03,tj,tj1,result);
   UCheb(x,8.058326e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 8, 10)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln8n10(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.554093e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.334282e+00,tj,tj1,result);
   UCheb(x,-4.700860e+00,tj,tj1,result);
   UCheb(x,-1.235253e+00,tj,tj1,result);
   UCheb(x,-2.778489e-01,tj,tj1,result);
   UCheb(x,-9.527324e-02,tj,tj1,result);
   UCheb(x,-3.862885e-02,tj,tj1,result);
   UCheb(x,-1.589781e-02,tj,tj1,result);
   UCheb(x,-6.507355e-03,tj,tj1,result);
   UCheb(x,-1.717526e-03,tj,tj1,result);
   UCheb(x,9.215726e-04,tj,tj1,result);
   UCheb(x,2.848696e-03,tj,tj1,result);
   UCheb(x,3.918854e-03,tj,tj1,result);
   UCheb(x,4.219614e-03,tj,tj1,result);
   UCheb(x,3.753761e-03,tj,tj1,result);
   UCheb(x,2.573688e-03,tj,tj1,result);
   UCheb(x,1.602177e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 8, 11)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln8n11(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.600000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.421882e+00,tj,tj1,result);
   UCheb(x,-4.812457e+00,tj,tj1,result);
   UCheb(x,-1.266153e+00,tj,tj1,result);
   UCheb(x,-2.849344e-01,tj,tj1,result);
   UCheb(x,-9.971527e-02,tj,tj1,result);
   UCheb(x,-4.258944e-02,tj,tj1,result);
   UCheb(x,-1.944820e-02,tj,tj1,result);
   UCheb(x,-9.894685e-03,tj,tj1,result);
   UCheb(x,-5.031836e-03,tj,tj1,result);
   UCheb(x,-2.514330e-03,tj,tj1,result);
   UCheb(x,-6.351660e-04,tj,tj1,result);
   UCheb(x,6.206748e-04,tj,tj1,result);
   UCheb(x,1.492600e-03,tj,tj1,result);
   UCheb(x,2.005338e-03,tj,tj1,result);
   UCheb(x,1.780099e-03,tj,tj1,result);
   UCheb(x,1.673599e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 8, 12)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln8n12(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.600000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.398211e+00,tj,tj1,result);
   UCheb(x,-4.762214e+00,tj,tj1,result);
   UCheb(x,-1.226296e+00,tj,tj1,result);
   UCheb(x,-2.603837e-01,tj,tj1,result);
   UCheb(x,-8.643223e-02,tj,tj1,result);
   UCheb(x,-3.502438e-02,tj,tj1,result);
   UCheb(x,-1.544574e-02,tj,tj1,result);
   UCheb(x,-7.647734e-03,tj,tj1,result);
   UCheb(x,-4.442259e-03,tj,tj1,result);
   UCheb(x,-3.011484e-03,tj,tj1,result);
   UCheb(x,-2.384758e-03,tj,tj1,result);
   UCheb(x,-1.998259e-03,tj,tj1,result);
   UCheb(x,-1.659985e-03,tj,tj1,result);
   UCheb(x,-1.331046e-03,tj,tj1,result);
   UCheb(x,-8.638478e-04,tj,tj1,result);
   UCheb(x,-6.056785e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 8, 13)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln8n13(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.600000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.380670e+00,tj,tj1,result);
   UCheb(x,-4.724511e+00,tj,tj1,result);
   UCheb(x,-1.195851e+00,tj,tj1,result);
   UCheb(x,-2.420511e-01,tj,tj1,result);
   UCheb(x,-7.609928e-02,tj,tj1,result);
   UCheb(x,-2.893999e-02,tj,tj1,result);
   UCheb(x,-1.115919e-02,tj,tj1,result);
   UCheb(x,-4.291410e-03,tj,tj1,result);
   UCheb(x,-1.339664e-03,tj,tj1,result);
   UCheb(x,-1.801548e-04,tj,tj1,result);
   UCheb(x,2.534710e-04,tj,tj1,result);
   UCheb(x,2.793250e-04,tj,tj1,result);
   UCheb(x,1.806718e-04,tj,tj1,result);
   UCheb(x,1.384624e-04,tj,tj1,result);
   UCheb(x,1.120582e-04,tj,tj1,result);
   UCheb(x,2.936453e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 8, 14)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln8n14(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.600000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.368494e+00,tj,tj1,result);
   UCheb(x,-4.697171e+00,tj,tj1,result);
   UCheb(x,-1.174440e+00,tj,tj1,result);
   UCheb(x,-2.300621e-01,tj,tj1,result);
   UCheb(x,-7.087393e-02,tj,tj1,result);
   UCheb(x,-2.685826e-02,tj,tj1,result);
   UCheb(x,-1.085254e-02,tj,tj1,result);
   UCheb(x,-4.525658e-03,tj,tj1,result);
   UCheb(x,-1.966647e-03,tj,tj1,result);
   UCheb(x,-7.453388e-04,tj,tj1,result);
   UCheb(x,-3.826066e-04,tj,tj1,result);
   UCheb(x,-3.501958e-04,tj,tj1,result);
   UCheb(x,-5.336297e-04,tj,tj1,result);
   UCheb(x,-8.251972e-04,tj,tj1,result);
   UCheb(x,-8.118456e-04,tj,tj1,result);
   UCheb(x,-9.415959e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 8, 15)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln8n15(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.600000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.358397e+00,tj,tj1,result);
   UCheb(x,-4.674485e+00,tj,tj1,result);
   UCheb(x,-1.155941e+00,tj,tj1,result);
   UCheb(x,-2.195780e-01,tj,tj1,result);
   UCheb(x,-6.544830e-02,tj,tj1,result);
   UCheb(x,-2.426183e-02,tj,tj1,result);
   UCheb(x,-9.309902e-03,tj,tj1,result);
   UCheb(x,-3.650956e-03,tj,tj1,result);
   UCheb(x,-1.068874e-03,tj,tj1,result);
   UCheb(x,1.538544e-04,tj,tj1,result);
   UCheb(x,8.192525e-04,tj,tj1,result);
   UCheb(x,1.073905e-03,tj,tj1,result);
   UCheb(x,1.079673e-03,tj,tj1,result);
   UCheb(x,9.423572e-04,tj,tj1,result);
   UCheb(x,6.579647e-04,tj,tj1,result);
   UCheb(x,4.765904e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 8, 30)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln8n30(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.600000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.318823e+00,tj,tj1,result);
   UCheb(x,-4.567159e+00,tj,tj1,result);
   UCheb(x,-1.064864e+00,tj,tj1,result);
   UCheb(x,-1.688413e-01,tj,tj1,result);
   UCheb(x,-4.153712e-02,tj,tj1,result);
   UCheb(x,-1.309389e-02,tj,tj1,result);
   UCheb(x,-4.226861e-03,tj,tj1,result);
   UCheb(x,-1.523815e-03,tj,tj1,result);
   UCheb(x,-5.780987e-04,tj,tj1,result);
   UCheb(x,-2.166866e-04,tj,tj1,result);
   UCheb(x,-6.922431e-05,tj,tj1,result);
   UCheb(x,-1.466397e-05,tj,tj1,result);
   UCheb(x,-5.690036e-06,tj,tj1,result);
   UCheb(x,-1.008185e-05,tj,tj1,result);
   UCheb(x,-9.271903e-06,tj,tj1,result);
   UCheb(x,-7.534751e-06,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 8, 100)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln8n100(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.600000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.324531e+00,tj,tj1,result);
   UCheb(x,-4.547071e+00,tj,tj1,result);
   UCheb(x,-1.038129e+00,tj,tj1,result);
   UCheb(x,-1.541549e-01,tj,tj1,result);
   UCheb(x,-3.525605e-02,tj,tj1,result);
   UCheb(x,-1.044992e-02,tj,tj1,result);
   UCheb(x,-3.085713e-03,tj,tj1,result);
   UCheb(x,-1.017871e-03,tj,tj1,result);
   UCheb(x,-3.459226e-04,tj,tj1,result);
   UCheb(x,-1.092064e-04,tj,tj1,result);
   UCheb(x,-2.024349e-05,tj,tj1,result);
   UCheb(x,7.366347e-06,tj,tj1,result);
   UCheb(x,6.385637e-06,tj,tj1,result);
   UCheb(x,8.321722e-08,tj,tj1,result);
   UCheb(x,-1.439286e-06,tj,tj1,result);
   UCheb(x,-3.058079e-07,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 9, 9)                                                    |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln9n9(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.576237e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.372857e+00,tj,tj1,result);
   UCheb(x,-4.750859e+00,tj,tj1,result);
   UCheb(x,-1.248233e+00,tj,tj1,result);
   UCheb(x,-2.792868e-01,tj,tj1,result);
   UCheb(x,-9.559372e-02,tj,tj1,result);
   UCheb(x,-3.894941e-02,tj,tj1,result);
   UCheb(x,-1.643256e-02,tj,tj1,result);
   UCheb(x,-7.091370e-03,tj,tj1,result);
   UCheb(x,-2.285034e-03,tj,tj1,result);
   UCheb(x,6.112997e-04,tj,tj1,result);
   UCheb(x,2.806229e-03,tj,tj1,result);
   UCheb(x,4.150741e-03,tj,tj1,result);
   UCheb(x,4.509825e-03,tj,tj1,result);
   UCheb(x,3.891051e-03,tj,tj1,result);
   UCheb(x,2.485013e-03,tj,tj1,result);
   UCheb(x,1.343653e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 9, 10)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln9n10(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.516726e+00,tj,tj1,result);
   UCheb(x,-4.939333e+00,tj,tj1,result);
   UCheb(x,-1.305046e+00,tj,tj1,result);
   UCheb(x,-2.935326e-01,tj,tj1,result);
   UCheb(x,-1.029141e-01,tj,tj1,result);
   UCheb(x,-4.420592e-02,tj,tj1,result);
   UCheb(x,-2.053140e-02,tj,tj1,result);
   UCheb(x,-1.065930e-02,tj,tj1,result);
   UCheb(x,-5.523581e-03,tj,tj1,result);
   UCheb(x,-2.544888e-03,tj,tj1,result);
   UCheb(x,-1.813741e-04,tj,tj1,result);
   UCheb(x,1.510631e-03,tj,tj1,result);
   UCheb(x,2.536057e-03,tj,tj1,result);
   UCheb(x,2.833815e-03,tj,tj1,result);
   UCheb(x,2.189692e-03,tj,tj1,result);
   UCheb(x,1.615050e-03,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 9, 11)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln9n11(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.481308e+00,tj,tj1,result);
   UCheb(x,-4.867483e+00,tj,tj1,result);
   UCheb(x,-1.249072e+00,tj,tj1,result);
   UCheb(x,-2.591790e-01,tj,tj1,result);
   UCheb(x,-8.400128e-02,tj,tj1,result);
   UCheb(x,-3.341992e-02,tj,tj1,result);
   UCheb(x,-1.463680e-02,tj,tj1,result);
   UCheb(x,-7.487211e-03,tj,tj1,result);
   UCheb(x,-4.671196e-03,tj,tj1,result);
   UCheb(x,-3.343472e-03,tj,tj1,result);
   UCheb(x,-2.544146e-03,tj,tj1,result);
   UCheb(x,-1.802335e-03,tj,tj1,result);
   UCheb(x,-1.117084e-03,tj,tj1,result);
   UCheb(x,-6.217443e-04,tj,tj1,result);
   UCheb(x,-2.858766e-04,tj,tj1,result);
   UCheb(x,-3.193687e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 9, 12)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln9n12(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.456776e+00,tj,tj1,result);
   UCheb(x,-4.817037e+00,tj,tj1,result);
   UCheb(x,-1.209788e+00,tj,tj1,result);
   UCheb(x,-2.362108e-01,tj,tj1,result);
   UCheb(x,-7.171356e-02,tj,tj1,result);
   UCheb(x,-2.661557e-02,tj,tj1,result);
   UCheb(x,-1.026141e-02,tj,tj1,result);
   UCheb(x,-4.361908e-03,tj,tj1,result);
   UCheb(x,-2.093885e-03,tj,tj1,result);
   UCheb(x,-1.298389e-03,tj,tj1,result);
   UCheb(x,-9.663603e-04,tj,tj1,result);
   UCheb(x,-7.768522e-04,tj,tj1,result);
   UCheb(x,-5.579015e-04,tj,tj1,result);
   UCheb(x,-2.868677e-04,tj,tj1,result);
   UCheb(x,-7.440652e-05,tj,tj1,result);
   UCheb(x,1.523037e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 9, 13)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln9n13(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.438840e+00,tj,tj1,result);
   UCheb(x,-4.779308e+00,tj,tj1,result);
   UCheb(x,-1.180614e+00,tj,tj1,result);
   UCheb(x,-2.196489e-01,tj,tj1,result);
   UCheb(x,-6.346621e-02,tj,tj1,result);
   UCheb(x,-2.234857e-02,tj,tj1,result);
   UCheb(x,-7.796211e-03,tj,tj1,result);
   UCheb(x,-2.575715e-03,tj,tj1,result);
   UCheb(x,-5.525647e-04,tj,tj1,result);
   UCheb(x,1.964651e-04,tj,tj1,result);
   UCheb(x,4.275235e-04,tj,tj1,result);
   UCheb(x,4.299124e-04,tj,tj1,result);
   UCheb(x,3.397416e-04,tj,tj1,result);
   UCheb(x,2.295781e-04,tj,tj1,result);
   UCheb(x,1.237619e-04,tj,tj1,result);
   UCheb(x,7.269692e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 9, 14)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln9n14(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.425981e+00,tj,tj1,result);
   UCheb(x,-4.751545e+00,tj,tj1,result);
   UCheb(x,-1.159543e+00,tj,tj1,result);
   UCheb(x,-2.086570e-01,tj,tj1,result);
   UCheb(x,-5.917446e-02,tj,tj1,result);
   UCheb(x,-2.120112e-02,tj,tj1,result);
   UCheb(x,-8.175519e-03,tj,tj1,result);
   UCheb(x,-3.515473e-03,tj,tj1,result);
   UCheb(x,-1.727772e-03,tj,tj1,result);
   UCheb(x,-9.070629e-04,tj,tj1,result);
   UCheb(x,-5.677569e-04,tj,tj1,result);
   UCheb(x,-3.876953e-04,tj,tj1,result);
   UCheb(x,-3.233502e-04,tj,tj1,result);
   UCheb(x,-3.508182e-04,tj,tj1,result);
   UCheb(x,-3.120389e-04,tj,tj1,result);
   UCheb(x,-3.847212e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 9, 15)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln9n15(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.414952e+00,tj,tj1,result);
   UCheb(x,-4.727612e+00,tj,tj1,result);
   UCheb(x,-1.140634e+00,tj,tj1,result);
   UCheb(x,-1.981231e-01,tj,tj1,result);
   UCheb(x,-5.382635e-02,tj,tj1,result);
   UCheb(x,-1.853575e-02,tj,tj1,result);
   UCheb(x,-6.571051e-03,tj,tj1,result);
   UCheb(x,-2.567625e-03,tj,tj1,result);
   UCheb(x,-9.214197e-04,tj,tj1,result);
   UCheb(x,-2.448700e-04,tj,tj1,result);
   UCheb(x,1.712669e-04,tj,tj1,result);
   UCheb(x,4.015050e-04,tj,tj1,result);
   UCheb(x,5.438610e-04,tj,tj1,result);
   UCheb(x,6.301363e-04,tj,tj1,result);
   UCheb(x,5.309386e-04,tj,tj1,result);
   UCheb(x,5.164772e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 9, 30)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln9n30(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.370720e+00,tj,tj1,result);
   UCheb(x,-4.615712e+00,tj,tj1,result);
   UCheb(x,-1.050023e+00,tj,tj1,result);
   UCheb(x,-1.504775e-01,tj,tj1,result);
   UCheb(x,-3.318265e-02,tj,tj1,result);
   UCheb(x,-9.646826e-03,tj,tj1,result);
   UCheb(x,-2.741492e-03,tj,tj1,result);
   UCheb(x,-8.735360e-04,tj,tj1,result);
   UCheb(x,-2.966911e-04,tj,tj1,result);
   UCheb(x,-1.100738e-04,tj,tj1,result);
   UCheb(x,-4.348991e-05,tj,tj1,result);
   UCheb(x,-1.527687e-05,tj,tj1,result);
   UCheb(x,-2.917286e-06,tj,tj1,result);
   UCheb(x,3.397466e-07,tj,tj1,result);
   UCheb(x,-2.360175e-07,tj,tj1,result);
   UCheb(x,-9.892252e-07,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 9, 100)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln9n100(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.372506e+00,tj,tj1,result);
   UCheb(x,-4.590966e+00,tj,tj1,result);
   UCheb(x,-1.021758e+00,tj,tj1,result);
   UCheb(x,-1.359849e-01,tj,tj1,result);
   UCheb(x,-2.755519e-02,tj,tj1,result);
   UCheb(x,-7.533166e-03,tj,tj1,result);
   UCheb(x,-1.936659e-03,tj,tj1,result);
   UCheb(x,-5.634913e-04,tj,tj1,result);
   UCheb(x,-1.730053e-04,tj,tj1,result);
   UCheb(x,-5.791845e-05,tj,tj1,result);
   UCheb(x,-2.030682e-05,tj,tj1,result);
   UCheb(x,-5.228663e-06,tj,tj1,result);
   UCheb(x,8.631175e-07,tj,tj1,result);
   UCheb(x,1.636749e-06,tj,tj1,result);
   UCheb(x,4.404599e-07,tj,tj1,result);
   UCheb(x,-2.789872e-07,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 10, 10)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln10n10(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.468831e+00,tj,tj1,result);
   UCheb(x,-4.844398e+00,tj,tj1,result);
   UCheb(x,-1.231728e+00,tj,tj1,result);
   UCheb(x,-2.486073e-01,tj,tj1,result);
   UCheb(x,-7.781321e-02,tj,tj1,result);
   UCheb(x,-2.971425e-02,tj,tj1,result);
   UCheb(x,-1.215371e-02,tj,tj1,result);
   UCheb(x,-5.828451e-03,tj,tj1,result);
   UCheb(x,-3.419872e-03,tj,tj1,result);
   UCheb(x,-2.430165e-03,tj,tj1,result);
   UCheb(x,-1.740363e-03,tj,tj1,result);
   UCheb(x,-1.049211e-03,tj,tj1,result);
   UCheb(x,-3.269371e-04,tj,tj1,result);
   UCheb(x,2.211393e-04,tj,tj1,result);
   UCheb(x,4.232314e-04,tj,tj1,result);
   UCheb(x,3.016081e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 10, 11)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln10n11(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.437998e+00,tj,tj1,result);
   UCheb(x,-4.782296e+00,tj,tj1,result);
   UCheb(x,-1.184732e+00,tj,tj1,result);
   UCheb(x,-2.219585e-01,tj,tj1,result);
   UCheb(x,-6.457012e-02,tj,tj1,result);
   UCheb(x,-2.296008e-02,tj,tj1,result);
   UCheb(x,-8.481501e-03,tj,tj1,result);
   UCheb(x,-3.527940e-03,tj,tj1,result);
   UCheb(x,-1.953426e-03,tj,tj1,result);
   UCheb(x,-1.563840e-03,tj,tj1,result);
   UCheb(x,-1.574403e-03,tj,tj1,result);
   UCheb(x,-1.535775e-03,tj,tj1,result);
   UCheb(x,-1.338037e-03,tj,tj1,result);
   UCheb(x,-1.002654e-03,tj,tj1,result);
   UCheb(x,-5.852676e-04,tj,tj1,result);
   UCheb(x,-3.318132e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 10, 12)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln10n12(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.416082e+00,tj,tj1,result);
   UCheb(x,-4.737458e+00,tj,tj1,result);
   UCheb(x,-1.150952e+00,tj,tj1,result);
   UCheb(x,-2.036884e-01,tj,tj1,result);
   UCheb(x,-5.609030e-02,tj,tj1,result);
   UCheb(x,-1.908684e-02,tj,tj1,result);
   UCheb(x,-6.439666e-03,tj,tj1,result);
   UCheb(x,-2.162647e-03,tj,tj1,result);
   UCheb(x,-6.451601e-04,tj,tj1,result);
   UCheb(x,-2.148757e-04,tj,tj1,result);
   UCheb(x,-1.803981e-04,tj,tj1,result);
   UCheb(x,-2.731621e-04,tj,tj1,result);
   UCheb(x,-3.346903e-04,tj,tj1,result);
   UCheb(x,-3.013151e-04,tj,tj1,result);
   UCheb(x,-1.956148e-04,tj,tj1,result);
   UCheb(x,-2.438381e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 10, 13)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln10n13(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.399480e+00,tj,tj1,result);
   UCheb(x,-4.702863e+00,tj,tj1,result);
   UCheb(x,-1.124829e+00,tj,tj1,result);
   UCheb(x,-1.897428e-01,tj,tj1,result);
   UCheb(x,-4.979802e-02,tj,tj1,result);
   UCheb(x,-1.634368e-02,tj,tj1,result);
   UCheb(x,-5.180461e-03,tj,tj1,result);
   UCheb(x,-1.484926e-03,tj,tj1,result);
   UCheb(x,-7.864376e-05,tj,tj1,result);
   UCheb(x,4.186576e-04,tj,tj1,result);
   UCheb(x,5.886925e-04,tj,tj1,result);
   UCheb(x,5.836828e-04,tj,tj1,result);
   UCheb(x,5.074756e-04,tj,tj1,result);
   UCheb(x,4.209547e-04,tj,tj1,result);
   UCheb(x,2.883266e-04,tj,tj1,result);
   UCheb(x,2.380143e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 10, 14)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln10n14(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.386924e+00,tj,tj1,result);
   UCheb(x,-4.676124e+00,tj,tj1,result);
   UCheb(x,-1.104740e+00,tj,tj1,result);
   UCheb(x,-1.793826e-01,tj,tj1,result);
   UCheb(x,-4.558886e-02,tj,tj1,result);
   UCheb(x,-1.492462e-02,tj,tj1,result);
   UCheb(x,-5.052903e-03,tj,tj1,result);
   UCheb(x,-1.917782e-03,tj,tj1,result);
   UCheb(x,-7.878696e-04,tj,tj1,result);
   UCheb(x,-3.576046e-04,tj,tj1,result);
   UCheb(x,-1.764551e-04,tj,tj1,result);
   UCheb(x,-9.288778e-05,tj,tj1,result);
   UCheb(x,-4.757658e-05,tj,tj1,result);
   UCheb(x,-2.299101e-05,tj,tj1,result);
   UCheb(x,-9.265197e-06,tj,tj1,result);
   UCheb(x,-2.384503e-07,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 10, 15)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln10n15(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.376846e+00,tj,tj1,result);
   UCheb(x,-4.654247e+00,tj,tj1,result);
   UCheb(x,-1.088083e+00,tj,tj1,result);
   UCheb(x,-1.705945e-01,tj,tj1,result);
   UCheb(x,-4.169677e-02,tj,tj1,result);
   UCheb(x,-1.317213e-02,tj,tj1,result);
   UCheb(x,-4.264836e-03,tj,tj1,result);
   UCheb(x,-1.548024e-03,tj,tj1,result);
   UCheb(x,-6.633910e-04,tj,tj1,result);
   UCheb(x,-3.505621e-04,tj,tj1,result);
   UCheb(x,-2.658588e-04,tj,tj1,result);
   UCheb(x,-2.320254e-04,tj,tj1,result);
   UCheb(x,-2.175277e-04,tj,tj1,result);
   UCheb(x,-2.122317e-04,tj,tj1,result);
   UCheb(x,-1.675688e-04,tj,tj1,result);
   UCheb(x,-1.661363e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 10, 30)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln10n30(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.333977e+00,tj,tj1,result);
   UCheb(x,-4.548099e+00,tj,tj1,result);
   UCheb(x,-1.004444e+00,tj,tj1,result);
   UCheb(x,-1.291014e-01,tj,tj1,result);
   UCheb(x,-2.523674e-02,tj,tj1,result);
   UCheb(x,-6.828211e-03,tj,tj1,result);
   UCheb(x,-1.716917e-03,tj,tj1,result);
   UCheb(x,-4.894256e-04,tj,tj1,result);
   UCheb(x,-1.433371e-04,tj,tj1,result);
   UCheb(x,-4.522675e-05,tj,tj1,result);
   UCheb(x,-1.764192e-05,tj,tj1,result);
   UCheb(x,-9.140235e-06,tj,tj1,result);
   UCheb(x,-5.629230e-06,tj,tj1,result);
   UCheb(x,-3.541895e-06,tj,tj1,result);
   UCheb(x,-1.944946e-06,tj,tj1,result);
   UCheb(x,-1.726360e-06,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 10, 100)                                                 |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln10n100(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.650000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.334008e+00,tj,tj1,result);
   UCheb(x,-4.522316e+00,tj,tj1,result);
   UCheb(x,-9.769627e-01,tj,tj1,result);
   UCheb(x,-1.158110e-01,tj,tj1,result);
   UCheb(x,-2.053650e-02,tj,tj1,result);
   UCheb(x,-5.242235e-03,tj,tj1,result);
   UCheb(x,-1.173571e-03,tj,tj1,result);
   UCheb(x,-3.033661e-04,tj,tj1,result);
   UCheb(x,-7.824732e-05,tj,tj1,result);
   UCheb(x,-2.084420e-05,tj,tj1,result);
   UCheb(x,-6.610036e-06,tj,tj1,result);
   UCheb(x,-2.728155e-06,tj,tj1,result);
   UCheb(x,-1.217130e-06,tj,tj1,result);
   UCheb(x,-2.340966e-07,tj,tj1,result);
   UCheb(x,2.001235e-07,tj,tj1,result);
   UCheb(x,1.694052e-07,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 11, 11)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln11n11(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.700000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.519760e+00,tj,tj1,result);
   UCheb(x,-4.880694e+00,tj,tj1,result);
   UCheb(x,-1.200698e+00,tj,tj1,result);
   UCheb(x,-2.174092e-01,tj,tj1,result);
   UCheb(x,-6.072304e-02,tj,tj1,result);
   UCheb(x,-2.054773e-02,tj,tj1,result);
   UCheb(x,-6.506613e-03,tj,tj1,result);
   UCheb(x,-1.813942e-03,tj,tj1,result);
   UCheb(x,-1.223644e-04,tj,tj1,result);
   UCheb(x,2.417416e-04,tj,tj1,result);
   UCheb(x,2.499166e-04,tj,tj1,result);
   UCheb(x,1.194332e-04,tj,tj1,result);
   UCheb(x,7.369096e-05,tj,tj1,result);
   UCheb(x,1.968590e-04,tj,tj1,result);
   UCheb(x,2.630532e-04,tj,tj1,result);
   UCheb(x,5.061000e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 11, 12)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln11n12(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.700000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.495790e+00,tj,tj1,result);
   UCheb(x,-4.832622e+00,tj,tj1,result);
   UCheb(x,-1.165420e+00,tj,tj1,result);
   UCheb(x,-1.987306e-01,tj,tj1,result);
   UCheb(x,-5.265621e-02,tj,tj1,result);
   UCheb(x,-1.723537e-02,tj,tj1,result);
   UCheb(x,-5.347406e-03,tj,tj1,result);
   UCheb(x,-1.353464e-03,tj,tj1,result);
   UCheb(x,6.613369e-05,tj,tj1,result);
   UCheb(x,5.102522e-04,tj,tj1,result);
   UCheb(x,5.237709e-04,tj,tj1,result);
   UCheb(x,3.665652e-04,tj,tj1,result);
   UCheb(x,1.626903e-04,tj,tj1,result);
   UCheb(x,-1.167518e-05,tj,tj1,result);
   UCheb(x,-8.564455e-05,tj,tj1,result);
   UCheb(x,-1.047320e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 11, 13)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln11n13(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.700000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.477880e+00,tj,tj1,result);
   UCheb(x,-4.796242e+00,tj,tj1,result);
   UCheb(x,-1.138769e+00,tj,tj1,result);
   UCheb(x,-1.851739e-01,tj,tj1,result);
   UCheb(x,-4.722104e-02,tj,tj1,result);
   UCheb(x,-1.548304e-02,tj,tj1,result);
   UCheb(x,-5.176683e-03,tj,tj1,result);
   UCheb(x,-1.817895e-03,tj,tj1,result);
   UCheb(x,-5.842451e-04,tj,tj1,result);
   UCheb(x,-8.935870e-05,tj,tj1,result);
   UCheb(x,8.421777e-05,tj,tj1,result);
   UCheb(x,1.238831e-04,tj,tj1,result);
   UCheb(x,8.867026e-05,tj,tj1,result);
   UCheb(x,1.458255e-05,tj,tj1,result);
   UCheb(x,-3.306259e-05,tj,tj1,result);
   UCheb(x,-8.961487e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 11, 14)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln11n14(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.700000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.463683e+00,tj,tj1,result);
   UCheb(x,-4.766969e+00,tj,tj1,result);
   UCheb(x,-1.117082e+00,tj,tj1,result);
   UCheb(x,-1.739574e-01,tj,tj1,result);
   UCheb(x,-4.238865e-02,tj,tj1,result);
   UCheb(x,-1.350306e-02,tj,tj1,result);
   UCheb(x,-4.425871e-03,tj,tj1,result);
   UCheb(x,-1.640172e-03,tj,tj1,result);
   UCheb(x,-6.660633e-04,tj,tj1,result);
   UCheb(x,-2.879883e-04,tj,tj1,result);
   UCheb(x,-1.349658e-04,tj,tj1,result);
   UCheb(x,-6.271795e-05,tj,tj1,result);
   UCheb(x,-3.304544e-05,tj,tj1,result);
   UCheb(x,-3.024201e-05,tj,tj1,result);
   UCheb(x,-2.816867e-05,tj,tj1,result);
   UCheb(x,-4.596787e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 11, 15)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln11n15(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.700000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.452526e+00,tj,tj1,result);
   UCheb(x,-4.743570e+00,tj,tj1,result);
   UCheb(x,-1.099705e+00,tj,tj1,result);
   UCheb(x,-1.650612e-01,tj,tj1,result);
   UCheb(x,-3.858285e-02,tj,tj1,result);
   UCheb(x,-1.187036e-02,tj,tj1,result);
   UCheb(x,-3.689241e-03,tj,tj1,result);
   UCheb(x,-1.294360e-03,tj,tj1,result);
   UCheb(x,-5.072623e-04,tj,tj1,result);
   UCheb(x,-2.278008e-04,tj,tj1,result);
   UCheb(x,-1.322382e-04,tj,tj1,result);
   UCheb(x,-9.131558e-05,tj,tj1,result);
   UCheb(x,-7.305669e-05,tj,tj1,result);
   UCheb(x,-6.825627e-05,tj,tj1,result);
   UCheb(x,-5.332689e-05,tj,tj1,result);
   UCheb(x,-6.120973e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 11, 30)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln11n30(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.700000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.402621e+00,tj,tj1,result);
   UCheb(x,-4.627440e+00,tj,tj1,result);
   UCheb(x,-1.011333e+00,tj,tj1,result);
   UCheb(x,-1.224126e-01,tj,tj1,result);
   UCheb(x,-2.232856e-02,tj,tj1,result);
   UCheb(x,-5.859347e-03,tj,tj1,result);
   UCheb(x,-1.377381e-03,tj,tj1,result);
   UCheb(x,-3.756709e-04,tj,tj1,result);
   UCheb(x,-1.033230e-04,tj,tj1,result);
   UCheb(x,-2.875472e-05,tj,tj1,result);
   UCheb(x,-8.608399e-06,tj,tj1,result);
   UCheb(x,-3.102943e-06,tj,tj1,result);
   UCheb(x,-1.740693e-06,tj,tj1,result);
   UCheb(x,-1.343139e-06,tj,tj1,result);
   UCheb(x,-9.196878e-07,tj,tj1,result);
   UCheb(x,-6.658062e-07,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 11, 100)                                                 |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln11n100(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.700000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.398795e+00,tj,tj1,result);
   UCheb(x,-4.596486e+00,tj,tj1,result);
   UCheb(x,-9.814761e-01,tj,tj1,result);
   UCheb(x,-1.085187e-01,tj,tj1,result);
   UCheb(x,-1.766529e-02,tj,tj1,result);
   UCheb(x,-4.379425e-03,tj,tj1,result);
   UCheb(x,-8.986351e-04,tj,tj1,result);
   UCheb(x,-2.214705e-04,tj,tj1,result);
   UCheb(x,-5.360075e-05,tj,tj1,result);
   UCheb(x,-1.260869e-05,tj,tj1,result);
   UCheb(x,-3.033307e-06,tj,tj1,result);
   UCheb(x,-7.727087e-07,tj,tj1,result);
   UCheb(x,-3.393883e-07,tj,tj1,result);
   UCheb(x,-2.242989e-07,tj,tj1,result);
   UCheb(x,-1.111928e-07,tj,tj1,result);
   UCheb(x,3.898823e-09,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 12, 12)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln12n12(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.700000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.472616e+00,tj,tj1,result);
   UCheb(x,-4.786627e+00,tj,tj1,result);
   UCheb(x,-1.132099e+00,tj,tj1,result);
   UCheb(x,-1.817523e-01,tj,tj1,result);
   UCheb(x,-4.570179e-02,tj,tj1,result);
   UCheb(x,-1.479511e-02,tj,tj1,result);
   UCheb(x,-4.799492e-03,tj,tj1,result);
   UCheb(x,-1.565350e-03,tj,tj1,result);
   UCheb(x,-3.530139e-04,tj,tj1,result);
   UCheb(x,1.380132e-04,tj,tj1,result);
   UCheb(x,3.242761e-04,tj,tj1,result);
   UCheb(x,3.576269e-04,tj,tj1,result);
   UCheb(x,3.018771e-04,tj,tj1,result);
   UCheb(x,1.933911e-04,tj,tj1,result);
   UCheb(x,9.002799e-05,tj,tj1,result);
   UCheb(x,-2.022048e-06,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 12,13)                                                   |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln12n13(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.700000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.454800e+00,tj,tj1,result);
   UCheb(x,-4.750794e+00,tj,tj1,result);
   UCheb(x,-1.105988e+00,tj,tj1,result);
   UCheb(x,-1.684754e-01,tj,tj1,result);
   UCheb(x,-4.011826e-02,tj,tj1,result);
   UCheb(x,-1.262579e-02,tj,tj1,result);
   UCheb(x,-4.044492e-03,tj,tj1,result);
   UCheb(x,-1.478741e-03,tj,tj1,result);
   UCheb(x,-5.322165e-04,tj,tj1,result);
   UCheb(x,-1.621104e-04,tj,tj1,result);
   UCheb(x,4.068753e-05,tj,tj1,result);
   UCheb(x,1.468396e-04,tj,tj1,result);
   UCheb(x,2.056235e-04,tj,tj1,result);
   UCheb(x,2.327375e-04,tj,tj1,result);
   UCheb(x,1.914877e-04,tj,tj1,result);
   UCheb(x,1.784191e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 12, 14)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln12n14(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.700000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.440910e+00,tj,tj1,result);
   UCheb(x,-4.722404e+00,tj,tj1,result);
   UCheb(x,-1.085254e+00,tj,tj1,result);
   UCheb(x,-1.579439e-01,tj,tj1,result);
   UCheb(x,-3.563738e-02,tj,tj1,result);
   UCheb(x,-1.066730e-02,tj,tj1,result);
   UCheb(x,-3.129346e-03,tj,tj1,result);
   UCheb(x,-1.014531e-03,tj,tj1,result);
   UCheb(x,-3.129679e-04,tj,tj1,result);
   UCheb(x,-8.000909e-05,tj,tj1,result);
   UCheb(x,1.996174e-05,tj,tj1,result);
   UCheb(x,6.377924e-05,tj,tj1,result);
   UCheb(x,8.936304e-05,tj,tj1,result);
   UCheb(x,1.051098e-04,tj,tj1,result);
   UCheb(x,9.025820e-05,tj,tj1,result);
   UCheb(x,8.730585e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 12, 15)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln12n15(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.700000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.430123e+00,tj,tj1,result);
   UCheb(x,-4.700008e+00,tj,tj1,result);
   UCheb(x,-1.068971e+00,tj,tj1,result);
   UCheb(x,-1.499725e-01,tj,tj1,result);
   UCheb(x,-3.250897e-02,tj,tj1,result);
   UCheb(x,-9.473145e-03,tj,tj1,result);
   UCheb(x,-2.680008e-03,tj,tj1,result);
   UCheb(x,-8.483350e-04,tj,tj1,result);
   UCheb(x,-2.766992e-04,tj,tj1,result);
   UCheb(x,-9.891081e-05,tj,tj1,result);
   UCheb(x,-4.015140e-05,tj,tj1,result);
   UCheb(x,-1.977756e-05,tj,tj1,result);
   UCheb(x,-8.707414e-06,tj,tj1,result);
   UCheb(x,1.114786e-06,tj,tj1,result);
   UCheb(x,6.238865e-06,tj,tj1,result);
   UCheb(x,1.381445e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 12, 30)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln12n30(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.700000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.380023e+00,tj,tj1,result);
   UCheb(x,-4.585782e+00,tj,tj1,result);
   UCheb(x,-9.838583e-01,tj,tj1,result);
   UCheb(x,-1.103394e-01,tj,tj1,result);
   UCheb(x,-1.834015e-02,tj,tj1,result);
   UCheb(x,-4.635212e-03,tj,tj1,result);
   UCheb(x,-9.948212e-04,tj,tj1,result);
   UCheb(x,-2.574169e-04,tj,tj1,result);
   UCheb(x,-6.747980e-05,tj,tj1,result);
   UCheb(x,-1.833672e-05,tj,tj1,result);
   UCheb(x,-5.722433e-06,tj,tj1,result);
   UCheb(x,-2.181038e-06,tj,tj1,result);
   UCheb(x,-1.206473e-06,tj,tj1,result);
   UCheb(x,-9.716003e-07,tj,tj1,result);
   UCheb(x,-7.476434e-07,tj,tj1,result);
   UCheb(x,-7.217700e-07,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 12, 100)                                                 |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln12n100(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.700000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.374567e+00,tj,tj1,result);
   UCheb(x,-4.553481e+00,tj,tj1,result);
   UCheb(x,-9.541334e-01,tj,tj1,result);
   UCheb(x,-9.701907e-02,tj,tj1,result);
   UCheb(x,-1.414757e-02,tj,tj1,result);
   UCheb(x,-3.404103e-03,tj,tj1,result);
   UCheb(x,-6.234388e-04,tj,tj1,result);
   UCheb(x,-1.453762e-04,tj,tj1,result);
   UCheb(x,-3.311060e-05,tj,tj1,result);
   UCheb(x,-7.317501e-06,tj,tj1,result);
   UCheb(x,-1.713888e-06,tj,tj1,result);
   UCheb(x,-3.309583e-07,tj,tj1,result);
   UCheb(x,-4.019804e-08,tj,tj1,result);
   UCheb(x,1.224829e-09,tj,tj1,result);
   UCheb(x,-1.349019e-08,tj,tj1,result);
   UCheb(x,-1.893302e-08,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 13, 13)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln13n13(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.750000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.541046e+00,tj,tj1,result);
   UCheb(x,-4.859047e+00,tj,tj1,result);
   UCheb(x,-1.130164e+00,tj,tj1,result);
   UCheb(x,-1.689719e-01,tj,tj1,result);
   UCheb(x,-3.950693e-02,tj,tj1,result);
   UCheb(x,-1.231455e-02,tj,tj1,result);
   UCheb(x,-3.976550e-03,tj,tj1,result);
   UCheb(x,-1.538455e-03,tj,tj1,result);
   UCheb(x,-7.245603e-04,tj,tj1,result);
   UCheb(x,-4.142647e-04,tj,tj1,result);
   UCheb(x,-2.831434e-04,tj,tj1,result);
   UCheb(x,-2.032483e-04,tj,tj1,result);
   UCheb(x,-1.488405e-04,tj,tj1,result);
   UCheb(x,-1.156927e-04,tj,tj1,result);
   UCheb(x,-7.949279e-05,tj,tj1,result);
   UCheb(x,-7.532700e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 13, 14)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln13n14(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.750000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.525655e+00,tj,tj1,result);
   UCheb(x,-4.828341e+00,tj,tj1,result);
   UCheb(x,-1.108110e+00,tj,tj1,result);
   UCheb(x,-1.579552e-01,tj,tj1,result);
   UCheb(x,-3.488307e-02,tj,tj1,result);
   UCheb(x,-1.032328e-02,tj,tj1,result);
   UCheb(x,-2.988741e-03,tj,tj1,result);
   UCheb(x,-9.766394e-04,tj,tj1,result);
   UCheb(x,-3.388950e-04,tj,tj1,result);
   UCheb(x,-1.338179e-04,tj,tj1,result);
   UCheb(x,-6.133440e-05,tj,tj1,result);
   UCheb(x,-3.023518e-05,tj,tj1,result);
   UCheb(x,-1.110570e-05,tj,tj1,result);
   UCheb(x,4.202332e-06,tj,tj1,result);
   UCheb(x,1.056132e-05,tj,tj1,result);
   UCheb(x,1.536323e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 13, 15)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln13n15(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.750000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.513585e+00,tj,tj1,result);
   UCheb(x,-4.803952e+00,tj,tj1,result);
   UCheb(x,-1.090686e+00,tj,tj1,result);
   UCheb(x,-1.495310e-01,tj,tj1,result);
   UCheb(x,-3.160314e-02,tj,tj1,result);
   UCheb(x,-9.073124e-03,tj,tj1,result);
   UCheb(x,-2.480313e-03,tj,tj1,result);
   UCheb(x,-7.478239e-04,tj,tj1,result);
   UCheb(x,-2.140914e-04,tj,tj1,result);
   UCheb(x,-5.311541e-05,tj,tj1,result);
   UCheb(x,-2.677105e-06,tj,tj1,result);
   UCheb(x,1.115464e-05,tj,tj1,result);
   UCheb(x,1.578563e-05,tj,tj1,result);
   UCheb(x,2.044604e-05,tj,tj1,result);
   UCheb(x,1.888939e-05,tj,tj1,result);
   UCheb(x,2.395644e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 13, 30)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln13n30(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.750000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.455999e+00,tj,tj1,result);
   UCheb(x,-4.678434e+00,tj,tj1,result);
   UCheb(x,-9.995491e-01,tj,tj1,result);
   UCheb(x,-1.078100e-01,tj,tj1,result);
   UCheb(x,-1.705220e-02,tj,tj1,result);
   UCheb(x,-4.258739e-03,tj,tj1,result);
   UCheb(x,-8.671526e-04,tj,tj1,result);
   UCheb(x,-2.185458e-04,tj,tj1,result);
   UCheb(x,-5.507764e-05,tj,tj1,result);
   UCheb(x,-1.411446e-05,tj,tj1,result);
   UCheb(x,-4.044355e-06,tj,tj1,result);
   UCheb(x,-1.285765e-06,tj,tj1,result);
   UCheb(x,-5.345282e-07,tj,tj1,result);
   UCheb(x,-3.066940e-07,tj,tj1,result);
   UCheb(x,-1.962037e-07,tj,tj1,result);
   UCheb(x,-1.723644e-07,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 13, 100)                                                 |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln13n100(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.750000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.446787e+00,tj,tj1,result);
   UCheb(x,-4.640804e+00,tj,tj1,result);
   UCheb(x,-9.671552e-01,tj,tj1,result);
   UCheb(x,-9.364990e-02,tj,tj1,result);
   UCheb(x,-1.274444e-02,tj,tj1,result);
   UCheb(x,-3.047440e-03,tj,tj1,result);
   UCheb(x,-5.161439e-04,tj,tj1,result);
   UCheb(x,-1.171729e-04,tj,tj1,result);
   UCheb(x,-2.562171e-05,tj,tj1,result);
   UCheb(x,-5.359762e-06,tj,tj1,result);
   UCheb(x,-1.275494e-06,tj,tj1,result);
   UCheb(x,-2.747635e-07,tj,tj1,result);
   UCheb(x,-5.700292e-08,tj,tj1,result);
   UCheb(x,-2.565559e-09,tj,tj1,result);
   UCheb(x,5.005396e-09,tj,tj1,result);
   UCheb(x,3.335794e-09,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 14, 14)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln14n14(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.750000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.510624e+00,tj,tj1,result);
   UCheb(x,-4.798584e+00,tj,tj1,result);
   UCheb(x,-1.087107e+00,tj,tj1,result);
   UCheb(x,-1.478532e-01,tj,tj1,result);
   UCheb(x,-3.098050e-02,tj,tj1,result);
   UCheb(x,-8.855986e-03,tj,tj1,result);
   UCheb(x,-2.409083e-03,tj,tj1,result);
   UCheb(x,-7.299536e-04,tj,tj1,result);
   UCheb(x,-2.176177e-04,tj,tj1,result);
   UCheb(x,-6.479417e-05,tj,tj1,result);
   UCheb(x,-1.812761e-05,tj,tj1,result);
   UCheb(x,-5.225872e-06,tj,tj1,result);
   UCheb(x,4.516521e-07,tj,tj1,result);
   UCheb(x,6.730551e-06,tj,tj1,result);
   UCheb(x,9.237563e-06,tj,tj1,result);
   UCheb(x,1.611820e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 14, 15)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln14n15(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.750000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.498681e+00,tj,tj1,result);
   UCheb(x,-4.774668e+00,tj,tj1,result);
   UCheb(x,-1.070267e+00,tj,tj1,result);
   UCheb(x,-1.399348e-01,tj,tj1,result);
   UCheb(x,-2.807239e-02,tj,tj1,result);
   UCheb(x,-7.845763e-03,tj,tj1,result);
   UCheb(x,-2.071773e-03,tj,tj1,result);
   UCheb(x,-6.261698e-04,tj,tj1,result);
   UCheb(x,-2.011695e-04,tj,tj1,result);
   UCheb(x,-7.305946e-05,tj,tj1,result);
   UCheb(x,-3.879295e-05,tj,tj1,result);
   UCheb(x,-2.999439e-05,tj,tj1,result);
   UCheb(x,-2.904438e-05,tj,tj1,result);
   UCheb(x,-2.944986e-05,tj,tj1,result);
   UCheb(x,-2.373908e-05,tj,tj1,result);
   UCheb(x,-2.140794e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 14, 30)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln14n30(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.750000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.440378e+00,tj,tj1,result);
   UCheb(x,-4.649587e+00,tj,tj1,result);
   UCheb(x,-9.807829e-01,tj,tj1,result);
   UCheb(x,-9.989753e-02,tj,tj1,result);
   UCheb(x,-1.463646e-02,tj,tj1,result);
   UCheb(x,-3.586580e-03,tj,tj1,result);
   UCheb(x,-6.745917e-04,tj,tj1,result);
   UCheb(x,-1.635398e-04,tj,tj1,result);
   UCheb(x,-3.923172e-05,tj,tj1,result);
   UCheb(x,-9.446699e-06,tj,tj1,result);
   UCheb(x,-2.613892e-06,tj,tj1,result);
   UCheb(x,-8.214073e-07,tj,tj1,result);
   UCheb(x,-3.651683e-07,tj,tj1,result);
   UCheb(x,-2.272777e-07,tj,tj1,result);
   UCheb(x,-1.464988e-07,tj,tj1,result);
   UCheb(x,-1.109803e-07,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 14, 100)                                                 |
//+------------------------------------------------------------------+
static double CMannWhitneyU::UTbln14n100(const double s)
  {
//--- create variables
   double result=0;
   double x;
   double tj;
   double tj1;
//--- assignments
   x=MathMin(2*(s-0.000000e+00)/3.750000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   UCheb(x,-4.429701e+00,tj,tj1,result);
   UCheb(x,-4.610577e+00,tj,tj1,result);
   UCheb(x,-9.482675e-01,tj,tj1,result);
   UCheb(x,-8.605550e-02,tj,tj1,result);
   UCheb(x,-1.062151e-02,tj,tj1,result);
   UCheb(x,-2.525154e-03,tj,tj1,result);
   UCheb(x,-3.835983e-04,tj,tj1,result);
   UCheb(x,-8.411440e-05,tj,tj1,result);
   UCheb(x,-1.744901e-05,tj,tj1,result);
   UCheb(x,-3.318850e-06,tj,tj1,result);
   UCheb(x,-7.692100e-07,tj,tj1,result);
   UCheb(x,-1.536270e-07,tj,tj1,result);
   UCheb(x,-3.705888e-08,tj,tj1,result);
   UCheb(x,-7.999599e-09,tj,tj1,result);
   UCheb(x,-2.908395e-09,tj,tj1,result);
   UCheb(x,1.546923e-09,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, N1, N2)                                                  |
//+------------------------------------------------------------------+
static double CMannWhitneyU::USigma(double s,const int n1,const int n2)
  {
//--- create variables
   double f0;
   double f1;
   double f2;
   double f3;
   double f4;
   double s0;
   double s1;
   double s2;
   double s3;
   double s4;
//--- n1=5,n2=5,6,7...
   if(MathMin(n1,n2)==5)
     {
      //--- check
      if(MathMax(n1,n2)==5)
         return(UTbln5n5(s));
      //--- check
      if(MathMax(n1,n2)==6)
         return(UTbln5n6(s));
      //--- check
      if(MathMax(n1,n2)==7)
         return(UTbln5n7(s));
      //--- check
      if(MathMax(n1,n2)==8)
         return(UTbln5n8(s));
      //--- check
      if(MathMax(n1,n2)==9)
         return(UTbln5n9(s));
      //--- check
      if(MathMax(n1,n2)==10)
         return(UTbln5n10(s));
      //--- check
      if(MathMax(n1,n2)==11)
         return(UTbln5n11(s));
      //--- check
      if(MathMax(n1,n2)==12)
         return(UTbln5n12(s));
      //--- check
      if(MathMax(n1,n2)==13)
         return(UTbln5n13(s));
      //--- check
      if(MathMax(n1,n2)==14)
         return(UTbln5n14(s));
      //--- check
      if(MathMax(n1,n2)==15)
         return(UTbln5n15(s));
      //--- check
      if(MathMax(n1,n2)==16)
         return(UTbln5n16(s));
      //--- check
      if(MathMax(n1,n2)==17)
         return(UTbln5n17(s));
      //--- check
      if(MathMax(n1,n2)==18)
         return(UTbln5n18(s));
      //--- check
      if(MathMax(n1,n2)==19)
         return(UTbln5n19(s));
      //--- check
      if(MathMax(n1,n2)==20)
         return(UTbln5n20(s));
      //--- check
      if(MathMax(n1,n2)==21)
         return(UTbln5n21(s));
      //--- check
      if(MathMax(n1,n2)==22)
         return(UTbln5n22(s));
      //--- check
      if(MathMax(n1,n2)==23)
         return(UTbln5n23(s));
      //--- check
      if(MathMax(n1,n2)==24)
         return(UTbln5n24(s));
      //--- check
      if(MathMax(n1,n2)==25)
         return(UTbln5n25(s));
      //--- check
      if(MathMax(n1,n2)==26)
         return(UTbln5n26(s));
      //--- check
      if(MathMax(n1,n2)==27)
         return(UTbln5n27(s));
      //--- check
      if(MathMax(n1,n2)==28)
         return(UTbln5n28(s));
      //--- check
      if(MathMax(n1,n2)==29)
         return(UTbln5n29(s));
      //--- check
      if(MathMax(n1,n2)>29)
        {
         f0=UTbln5n15(s);
         f1=UTbln5n30(s);
         f2=UTbln5n100(s);
         //--- return result
         return(UThreePointInterpolate(f0,f1,f2,MathMax(n1,n2)));
        }
     }
//--- n1=6,n2=6,7,8...
   if(MathMin(n1,n2)==6)
     {
      //--- check
      if(MathMax(n1,n2)==6)
         return(UTbln6n6(s));
      //--- check
      if(MathMax(n1,n2)==7)
         return(UTbln6n7(s));
      //--- check
      if(MathMax(n1,n2)==8)
         return(UTbln6n8(s));
      //--- check
      if(MathMax(n1,n2)==9)
         return(UTbln6n9(s));
      //--- check
      if(MathMax(n1,n2)==10)
         return(UTbln6n10(s));
      //--- check
      if(MathMax(n1,n2)==11)
         return(UTbln6n11(s));
      //--- check
      if(MathMax(n1,n2)==12)
         return(UTbln6n12(s));
      //--- check
      if(MathMax(n1,n2)==13)
         return(UTbln6n13(s));
      //--- check
      if(MathMax(n1,n2)==14)
         return(UTbln6n14(s));
      //--- check
      if(MathMax(n1,n2)==15)
         return(UTbln6n15(s));
      //--- check
      if(MathMax(n1,n2)>15)
        {
         f0=UTbln6n15(s);
         f1=UTbln6n30(s);
         f2=UTbln6n100(s);
         //--- return result
         return(UThreePointInterpolate(f0,f1,f2,MathMax(n1,n2)));
        }
     }
//--- n1=7,n2=7,8,9...
   if(MathMin(n1,n2)==7)
     {
      //--- check
      if(MathMax(n1,n2)==7)
         return(UTbln7n7(s));
      //--- check
      if(MathMax(n1,n2)==8)
         return(UTbln7n8(s));
      //--- check
      if(MathMax(n1,n2)==9)
         return(UTbln7n9(s));
      //--- check
      if(MathMax(n1,n2)==10)
         return(UTbln7n10(s));
      //--- check
      if(MathMax(n1,n2)==11)
         return(UTbln7n11(s));
      //--- check
      if(MathMax(n1,n2)==12)
         return(UTbln7n12(s));
      //--- check
      if(MathMax(n1,n2)==13)
         return(UTbln7n13(s));
      //--- check
      if(MathMax(n1,n2)==14)
         return(UTbln7n14(s));
      //--- check
      if(MathMax(n1,n2)==15)
         return(UTbln7n15(s));
      //--- check
      if(MathMax(n1,n2)>15)
        {
         f0=UTbln7n15(s);
         f1=UTbln7n30(s);
         f2=UTbln7n100(s);
         //--- return result
         return(UThreePointInterpolate(f0,f1,f2,MathMax(n1,n2)));
        }
     }
//--- n1=8,n2=8,9,10...
   if(MathMin(n1,n2)==8)
     {
      //--- check
      if(MathMax(n1,n2)==8)
         return(UTbln8n8(s));
      //--- check
      if(MathMax(n1,n2)==9)
         return(UTbln8n9(s));
      //--- check
      if(MathMax(n1,n2)==10)
         return(UTbln8n10(s));
      //--- check
      if(MathMax(n1,n2)==11)
         return(UTbln8n11(s));
      //--- check
      if(MathMax(n1,n2)==12)
         return(UTbln8n12(s));
      //--- check
      if(MathMax(n1,n2)==13)
         return(UTbln8n13(s));
      //--- check
      if(MathMax(n1,n2)==14)
         return(UTbln8n14(s));
      //--- check
      if(MathMax(n1,n2)==15)
         return(UTbln8n15(s));
      //--- check
      if(MathMax(n1,n2)>15)
        {
         f0=UTbln8n15(s);
         f1=UTbln8n30(s);
         f2=UTbln8n100(s);
         //--- return result
         return(UThreePointInterpolate(f0,f1,f2,MathMax(n1,n2)));
        }
     }
//--- n1=9,n2=9,10,11...
   if(MathMin(n1,n2)==9)
     {
      //--- check
      if(MathMax(n1,n2)==9)
         return(UTbln9n9(s));
      //--- check
      if(MathMax(n1,n2)==10)
         return(UTbln9n10(s));
      //--- check
      if(MathMax(n1,n2)==11)
         return(UTbln9n11(s));
      //--- check
      if(MathMax(n1,n2)==12)
         return(UTbln9n12(s));
      //--- check
      if(MathMax(n1,n2)==13)
         return(UTbln9n13(s));
      //--- check
      if(MathMax(n1,n2)==14)
         return(UTbln9n14(s));
      //--- check
      if(MathMax(n1,n2)==15)
         return(UTbln9n15(s));
      //--- check
      if(MathMax(n1,n2)>15)
        {
         f0=UTbln9n15(s);
         f1=UTbln9n30(s);
         f2=UTbln9n100(s);
         //--- return result
         return(UThreePointInterpolate(f0,f1,f2,MathMax(n1,n2)));
        }
     }
//--- n1=10,n2=10,11,12...
   if(MathMin(n1,n2)==10)
     {
      //--- check
      if(MathMax(n1,n2)==10)
         return(UTbln10n10(s));
      //--- check
      if(MathMax(n1,n2)==11)
         return(UTbln10n11(s));
      //--- check
      if(MathMax(n1,n2)==12)
         return(UTbln10n12(s));
      //--- check
      if(MathMax(n1,n2)==13)
         return(UTbln10n13(s));
      //--- check
      if(MathMax(n1,n2)==14)
         return(UTbln10n14(s));
      //--- check
      if(MathMax(n1,n2)==15)
         return(UTbln10n15(s));
      //--- check
      if(MathMax(n1,n2)>15)
        {
         f0=UTbln10n15(s);
         f1=UTbln10n30(s);
         f2=UTbln10n100(s);
         //--- return result
         return(UThreePointInterpolate(f0,f1,f2,MathMax(n1,n2)));
        }
     }
//--- n1=11,n2=11,12,13...
   if(MathMin(n1,n2)==11)
     {
      //--- check
      if(MathMax(n1,n2)==11)
         return(UTbln11n11(s));
      //--- check
      if(MathMax(n1,n2)==12)
         return(UTbln11n12(s));
      //--- check
      if(MathMax(n1,n2)==13)
         return(UTbln11n13(s));
      //--- check
      if(MathMax(n1,n2)==14)
         return(UTbln11n14(s));
      //--- check
      if(MathMax(n1,n2)==15)
         return(UTbln11n15(s));
      //--- check
      if(MathMax(n1,n2)>15)
        {
         f0=UTbln11n15(s);
         f1=UTbln11n30(s);
         f2=UTbln11n100(s);
         //--- return result
         return(UThreePointInterpolate(f0,f1,f2,MathMax(n1,n2)));
        }
     }
//--- n1=12,n2=12,13,14...
   if(MathMin(n1,n2)==12)
     {
      //--- check
      if(MathMax(n1,n2)==12)
         return(UTbln12n12(s));
      //--- check
      if(MathMax(n1,n2)==13)
         return(UTbln12n13(s));
      //--- check
      if(MathMax(n1,n2)==14)
         return(UTbln12n14(s));
      //--- check
      if(MathMax(n1,n2)==15)
         return(UTbln12n15(s));
      //--- check
      if(MathMax(n1,n2)>15)
        {
         f0=UTbln12n15(s);
         f1=UTbln12n30(s);
         f2=UTbln12n100(s);
         //--- return result
         return(UThreePointInterpolate(f0,f1,f2,MathMax(n1,n2)));
        }
     }
//--- n1=13,n2=13,14,15...
   if(MathMin(n1,n2)==13)
     {
      //--- check
      if(MathMax(n1,n2)==13)
         return(UTbln13n13(s));
      //--- check
      if(MathMax(n1,n2)==14)
         return(UTbln13n14(s));
      //--- check
      if(MathMax(n1,n2)==15)
         return(UTbln13n15(s));
      //--- check
      if(MathMax(n1,n2)>15)
        {
         f0=UTbln13n15(s);
         f1=UTbln13n30(s);
         f2=UTbln13n100(s);
         //--- return result
         return(UThreePointInterpolate(f0,f1,f2,MathMax(n1,n2)));
        }
     }
//--- n1=14,n2=14,15...
   if(MathMin(n1,n2)==14)
     {
      //--- check
      if(MathMax(n1,n2)==14)
         return(UTbln14n14(s));
      //--- check
      if(MathMax(n1,n2)==15)
         return(UTbln14n15(s));
      //--- check
      if(MathMax(n1,n2)>15)
        {
         f0=UTbln14n15(s);
         f1=UTbln14n30(s);
         f2=UTbln14n100(s);
         //--- return result
         return(UThreePointInterpolate(f0,f1,f2,MathMax(n1,n2)));
        }
     }
//--- n1>=15,n2>=15...
   if(s>4)
      s=4;
//--- check
   if(s<3)
     {
      //--- calculation
      s0=0.000000e+00;
      f0=USigma000(n1,n2);
      s1=7.500000e-01;
      f1=USigma075(n1,n2);
      s2=1.500000e+00;
      f2=USigma150(n1,n2);
      s3=2.250000e+00;
      f3=USigma225(n1,n2);
      s4=3.000000e+00;
      f4=USigma300(n1,n2);
      //--- calculation result
      f1=((s-s0)*f1-(s-s1)*f0)/(s1-s0);
      f2=((s-s0)*f2-(s-s2)*f0)/(s2-s0);
      f3=((s-s0)*f3-(s-s3)*f0)/(s3-s0);
      f4=((s-s0)*f4-(s-s4)*f0)/(s4-s0);
      f2=((s-s1)*f2-(s-s2)*f1)/(s2-s1);
      f3=((s-s1)*f3-(s-s3)*f1)/(s3-s1);
      f4=((s-s1)*f4-(s-s4)*f1)/(s4-s1);
      f3=((s-s2)*f3-(s-s3)*f2)/(s3-s2);
      f4=((s-s2)*f4-(s-s4)*f2)/(s4-s2);
      f4=((s-s3)*f4-(s-s4)*f3)/(s4-s3);
      //--- return result
      return(f4);
     }
//--- else
   s0=3.000000e+00;
   f0=USigma300(n1,n2);
   s1=3.333333e+00;
   f1=USigma333(n1,n2);
   s2=3.666667e+00;
   f2=USigma367(n1,n2);
   s3=4.000000e+00;
   f3=USigma400(n1,n2);
//--- calculation result
   f1=((s-s0)*f1-(s-s1)*f0)/(s1-s0);
   f2=((s-s0)*f2-(s-s2)*f0)/(s2-s0);
   f3=((s-s0)*f3-(s-s3)*f0)/(s3-s0);
   f2=((s-s1)*f2-(s-s2)*f1)/(s2-s1);
   f3=((s-s1)*f3-(s-s3)*f1)/(s3-s1);
   f3=((s-s2)*f3-(s-s3)*f2)/(s3-s2);
//--- return result
   return(f3);
  }
//+------------------------------------------------------------------+
//| Sign test                                                        |
//+------------------------------------------------------------------+
class CSignTest
  {
public:
   //--- constructor, destructor
                     CSignTest(void);
                    ~CSignTest(void);
   //--- method
   static void       OneSampleSignTest(const double &x[],const int n,const double median,double &bothTails,double &leftTail,double &rightTail);
  };
//+------------------------------------------------------------------+
//| Constructor without parameters                                   |
//+------------------------------------------------------------------+
CSignTest::CSignTest(void)
  {

  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignTest::~CSignTest(void)
  {

  }
//+------------------------------------------------------------------+
//| Sign test                                                        |
//| This test checks three hypotheses about the median of the given  |
//| sample.                                                          |
//| The following tests are performed:                               |
//|     * two-tailed test (null hypothesis - the median is equal to  |
//|       the given value)                                           |
//|     * left-tailed test (null hypothesis - the median is greater  |
//|       than or equal to the given value)                          |
//|     * right-tailed test (null hypothesis - the  median is less   |
//|       than or equal to the given value)                          |
//| Requirements:                                                    |
//|     * the scale of measurement should be ordinal, interval or    |
//|       ratio (i.e. the test could not be applied to nominal       |
//|       variables).                                                |
//| The test is non-parametric and doesn't require distribution X to |
//| be normal                                                        |
//| Input parameters:                                                |
//|     X       -   sample. Array whose index goes from 0 to N-1.    |
//|     N       -   size of the sample.                              |
//|     Median  -   assumed median value.                            |
//| Output parameters:                                               |
//|     BothTails   -   p-value for two-tailed test.                 |
//|                     If BothTails is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//|     LeftTail    -   p-value for left-tailed test.                |
//|                     If LeftTail is less than the given           |
//|                     significance level, the null hypothesis is   |
//|                     rejected.                                    |
//|     RightTail   -   p-value for right-tailed test.               |
//|                     If RightTail is less than the given          |
//|                     significance levelthe null hypothesis is     |
//|                     rejected.                                    |
//| While calculating p-values high-precision binomial distribution  |
//| approximation is used, so significance levels have about 15 exact|
//| digits.                                                          |
//+------------------------------------------------------------------+
static void CSignTest::OneSampleSignTest(const double &x[],const int n,
                                         const double median,double &bothTails,
                                         double &leftTail,double &rightTail)
  {
//--- check
   if(n<=1)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      return;
     }
//--- Calculate:
//--- GTCnt - count of x[i]>Median
//--- NECnt - count of x[i]<>Median
   int i;
   int greater=0;
   int noteql=0;
//--- calculation
   for(i=0;i<n;i++)
     {
      //--- check
      if(x[i]>median)
         greater++;
      //--- check
      if(x[i]!=median)
         noteql++;
     }
//--- check
   if(noteql==0)
     {
      bothTails=0.0;
      leftTail=0.0;
      rightTail=0.0;
      return;
     }
//--- calculation
   bothTails=2*CBinomialDistr::BinomialDistribution(MathMin(greater,noteql-greater),noteql,0.5);
   leftTail=CBinomialDistr::BinomialDistribution(greater,noteql,0.5);
   rightTail=CBinomialDistr::BinomialComplDistribution(greater-1,noteql,0.5);
  }
//+------------------------------------------------------------------+
//| Studentt tests                                                   |
//+------------------------------------------------------------------+
class CStudentTests
  {
public:
   //--- constructor, destructor
                     CStudentTests(void);
                    ~CStudentTests(void);
   //--- methods
   static void       StudentTest1(const double &x[],const int n,const double mean,double &bothTails,double &leftTail,double &rightTail);
   static void       StudentTest2(const double &x[],const int n,const double &y[],const int m,double &bothTails,double &leftTail,double &rightTail);
   static void       UnequalVarianceTest(const double &x[],const int n,const double &y[],const int m,double &bothTails,double &leftTail,double &rightTail);
  };
//+------------------------------------------------------------------+
//| Constructor without parameters                                   |
//+------------------------------------------------------------------+
CStudentTests::CStudentTests(void)
  {

  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CStudentTests::~CStudentTests(void)
  {

  }
//+------------------------------------------------------------------+
//| One-sample t-test                                                |
//| This test checks three hypotheses about the mean of the given    |
//| sample. The following tests are performed:                       |
//|     * two-tailed test (null hypothesis - the mean is equal to the|
//|       given value)                                               |
//|     * left-tailed test (null hypothesis - the mean is greater    |
//|       than or equal to the given value)                          |
//|     * right-tailed test (null hypothesis - the mean is less than |
//|       or equal to the given value).                              |
//| The test is based on the assumption that a given sample has a    |
//| normal distribution and an unknown dispersion. If the            |
//| distribution sharply differs from normal, the test will work     |
//| incorrectly.                                                     |
//| Input parameters:                                                |
//|     X       -   sample. Array whose index goes from 0 to N-1.    |
//|     N       -   size of sample.                                  |
//|     Mean    -   assumed value of the mean.                       |
//| Output parameters:                                               |
//|     BothTails   -   p-value for two-tailed test.                 |
//|                     If BothTails is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//|     LeftTail    -   p-value for left-tailed test.                |
//|                     If LeftTail is less than the given           |
//|                     significance level, the null hypothesis is   |
//|                     rejected.                                    |
//|     RightTail   -   p-value for right-tailed test.               |
//|                     If RightTail is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//+------------------------------------------------------------------+
static void CStudentTests::StudentTest1(const double &x[],const int n,
                                        const double mean,double &bothTails,
                                        double &leftTail,double &rightTail)
  {
//--- check
   if(n<=1)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      //--- exit the function
      return;
     }
//--- create variables
   int    i;
   double xmean;
   double xvariance=0;
   double xstddev=0;
   double v1=0;
   double v2=0;
   double stat=0;
   double s=0;
//--- Mean
   xmean=0;
   for(i=0;i<n;i++)
      xmean+=x[i];
   xmean=xmean/n;
//--- Variance (using corrected two-pass algorithm)
   if(n!=1)
     {
      for(i=0;i<n;i++)
         v1+=CMath::Sqr(x[i]-xmean);
      for(i=0;i<n;i++)
         v2+=x[i]-xmean;
      v2=CMath::Sqr(v2)/n;
      //--- calculation
      xvariance=(v1-v2)/(n-1);
      //--- check
      if(xvariance<0)
         xvariance=0;
      xstddev=MathSqrt(xvariance);
     }
//--- check
   if(xstddev==0)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      //--- exit the function
      return;
     }
//--- Statistic
   stat=(xmean-mean)/(xstddev/MathSqrt(n));
   s=CStudenttDistr::StudenttDistribution(n-1,stat);
//--- get parameters
   bothTails=2*MathMin(s,1-s);
   leftTail=s;
   rightTail=1-s;
  }
//+------------------------------------------------------------------+
//| Two-sample pooled test                                           |
//| This test checks three hypotheses about the mean of the given    |
//| samples. The following tests are performed:                      |
//|     * two-tailed test (null hypothesis - the means are equal)    |
//|     * left-tailed test (null hypothesis - the mean of the first  |
//|       sample is greater than or equal to the mean of the second  |
//|       sample)                                                    |
//|     * right-tailed test (null hypothesis - the mean of the first |
//|       sample is less than or equal to the mean of the second     |
//|       sample).                                                   |
//| Test is based on the following assumptions:                      |
//|     * given samples have normal distributions                    |
//|     * dispersions are equal                                      |
//|     * samples are independent.                                   |
//| Input parameters:                                                |
//|     X       -   sample 1. Array whose index goes from 0 to N-1.  |
//|     N       -   size of sample.                                  |
//|     Y       -   sample 2. Array whose index goes from 0 to M-1.  |
//|     M       -   size of sample.                                  |
//| Output parameters:                                               |
//|     BothTails   -   p-value for two-tailed test.                 |
//|                     If BothTails is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//|     LeftTail    -   p-value for left-tailed test.                |
//|                     If LeftTail is less than the given           |
//|                     significance level, the null hypothesis is   |
//|                     rejected.                                    |
//|     RightTail   -   p-value for right-tailed test.               |
//|                     If RightTail is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//+------------------------------------------------------------------+
static void CStudentTests::StudentTest2(const double &x[],const int n,
                                        const double &y[],const int m,
                                        double &bothTails,double &leftTail,
                                        double &rightTail)
  {
//--- check
   if(n<=1 || m<=1)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      //--- exit the function
      return;
     }
//--- create variables
   int    i=0;
   double xmean=0;
   double ymean=0;
   double stat=0;
   double s=0;
   double p=0;
//--- Mean
   for(i=0;i<n;i++)
      xmean=xmean+x[i];
   xmean=xmean/n;
//--- y
   for(i=0;i<m;i++)
      ymean=ymean+y[i];
   ymean=ymean/m;
//--- S
   for(i=0;i<n;i++)
      s+=CMath::Sqr(x[i]-xmean);
   for(i=0;i<m;i++)
      s+=CMath::Sqr(y[i]-ymean);
   s=MathSqrt(s*(1.0/(double)n+1.0/(double)m)/(n+m-2));
//--- check
   if(s==0)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      //--- exit the function
      return;
     }
//--- Statistic
   stat=(xmean-ymean)/s;
   p=CStudenttDistr::StudenttDistribution(n+m-2,stat);
//--- get parameters
   bothTails=2*MathMin(p,1-p);
   leftTail=p;
   rightTail=1-p;
  }
//+------------------------------------------------------------------+
//| Two-sample unpooled test                                         |
//| This test checks three hypotheses about the mean of the given    |
//| samples. The following tests are performed:                      |
//|     * two-tailed test (null hypothesis - the means are equal)    |
//|     * left-tailed test (null hypothesis - the mean of the first  |
//|       sample  is greater than or equal to the mean of the second |
//|       sample)                                                    |
//|     * right-tailed test (null hypothesis - the mean of the first |
//|       sample is less than or equal to the mean of the second     |
//|       sample).                                                   |
//| Test is based on the following assumptions:                      |
//|     * given samples have normal distributions                    |
//|     * samples are independent.                                   |
//| Dispersion equality is not required                              |
//| Input parameters:                                                |
//|     X - sample 1. Array whose index goes from 0 to N-1.          |
//|     N - size of the sample.                                      |
//|     Y - sample 2. Array whose index goes from 0 to M-1.          |
//|     M - size of the sample.                                      |
//| Output parameters:                                               |
//|     BothTails   -   p-value for two-tailed test.                 |
//|                     If BothTails is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//|     LeftTail    -   p-value for left-tailed test.                |
//|                     If LeftTail is less than the given           |
//|                     significance level, the null hypothesis is   |
//|                     rejected.                                    |
//|     RightTail   -   p-value for right-tailed test.               |
//|                     If RightTail is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//+------------------------------------------------------------------+
static void CStudentTests::UnequalVarianceTest(const double &x[],const int n,
                                               const double &y[],const int m,
                                               double &bothTails,double &leftTail,
                                               double &rightTail)
  {
//--- check
   if(n<=1 || m<=1)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      //--- exit the function
      return;
     }
//--- create variables
   int    i;
   double xmean=0;
   double ymean=0;
   double xvar=0;
   double yvar=0;
   double df=0;
   double p=0;
   double stat=0;
   double c=0;
//--- Mean
   for(i=0; i<n; i++)
      xmean+=x[i];
   xmean=xmean/n;
   for(i=0; i<=m-1;i++)
      ymean+=y[i];
   ymean=ymean/m;
//--- Variance (using corrected two-pass algorithm)
   for(i=0;i<n;i++)
      xvar+=CMath::Sqr(x[i]-xmean);
   xvar=xvar/(n-1);
   for(i=0; i<=m-1;i++)
      yvar+=CMath::Sqr(y[i]-ymean);
   yvar=yvar/(m-1);
//--- check
   if(xvar==0 || yvar==0)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      //--- exit the function
      return;
     }
//--- Statistic
   stat=(xmean-ymean)/MathSqrt(xvar/n+yvar/m);
   c=xvar/n/(xvar/n+yvar/m);
   df=(n-1)*(m-1)/((m-1)*CMath::Sqr(c)+(n-1)*CMath::Sqr(1-c));
//--- check
   if(stat>0)
      p=1-0.5*CIncBetaF::IncompleteBeta(df/2,0.5,df/(df+CMath::Sqr(stat)));
   else
      p=0.5*CIncBetaF::IncompleteBeta(df/2,0.5,df/(df+CMath::Sqr(stat)));
//--- get parameters
   bothTails=2*MathMin(p,1-p);
   leftTail=p;
   rightTail=1-p;
  }
//+------------------------------------------------------------------+
//| Variance tests                                                   |
//+------------------------------------------------------------------+
class CVarianceTests
  {
public:
   //--- constructor, destructor
                     CVarianceTests(void);
                    ~CVarianceTests(void);
   //--- method
   static void       FTest(const double &x[],const int n,const double &y[],const int m,double &bothTails,double &leftTail,double &rightTail);
   static void       OneSampleVarianceTest(const double &x[],const int n,const double variance,double &bothTails,double &leftTail,double &rightTail);
  };
//+------------------------------------------------------------------+
//| Constructor without parameters                                   |
//+------------------------------------------------------------------+
CVarianceTests::CVarianceTests(void)
  {

  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CVarianceTests::~CVarianceTests(void)
  {

  }
//+------------------------------------------------------------------+
//| Two-sample F-test                                                |
//| This test checks three hypotheses about dispersions of the given |
//| samples. The following tests are performed:                      |
//|     * two-tailed test (null hypothesis - the dispersions are     |
//|       equal)                                                     |
//|     * left-tailed test (null hypothesis - the dispersion of the  |
//|       first sample is greater than or equal to the dispersion of |
//|       the second sample).                                        |
//|     * right-tailed test (null hypothesis - the dispersion of the |
//|       first sample is less than or equal to the dispersion of    |
//|       the second sample)                                         |
//| The test is based on the following assumptions:                  |
//|     * the given samples have normal distributions                |
//|     * the samples are independent.                               |
//| Input parameters:                                                |
//|     X   -   sample 1. Array whose index goes from 0 to N-1.      |
//|     N   -   sample size.                                         |
//|     Y   -   sample 2. Array whose index goes from 0 to M-1.      |
//|     M   -   sample size.                                         |
//| Output parameters:                                               |
//|     BothTails   -   p-value for two-tailed test.                 |
//|                     If BothTails is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//|     LeftTail    -   p-value for left-tailed test.                |
//|                     If LeftTail is less than the given           |
//|                     significance level, the null hypothesis is   |
//|                     rejected.                                    |
//|     RightTail   -   p-value for right-tailed test.               |
//|                     If RightTail is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//+------------------------------------------------------------------+
static void CVarianceTests::FTest(const double &x[],const int n,const double &y[],
                                  const int m,double &bothTails,double &leftTail,
                                  double &rightTail)
  {
//--- check
   if(n<=2 || m<=2)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      //--- exit the function
      return;
     }
//--- create variables
   int    i;
   double xmean=0;
   double ymean=0;
   double xvar=0;
   double yvar=0;
   int    df1=0;
   int    df2=0;
   double stat=0;
//--- Mean
   for(i=0; i<=n-1; i++)
      xmean+=x[i];
   xmean=xmean/n;
   for(i=0; i<=m-1; i++)
      ymean+=y[i];
   ymean=ymean/m;
//--- Variance (using corrected two-pass algorithm)
   for(i=0;i<n;i++)
      xvar+=CMath::Sqr(x[i]-xmean);
   xvar=xvar/(n-1);
   for(i=0;i<m;i++)
      yvar+=CMath::Sqr(y[i]-ymean);
   yvar=yvar/(m-1);
//--- check
   if((double)(xvar)==(double)(0)||(double)(yvar)==(double)(0))
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      //--- exit the function
      return;
     }
//--- Statistic
   df1=n-1;
   df2=m-1;
   stat=MathMin(xvar/yvar,yvar/xvar);
//--- get parameters
   bothTails=1-(CFDistr::FDistribution(df1,df2,1/stat)-CFDistr::FDistribution(df1,df2,stat));
   leftTail=CFDistr::FDistribution(df1,df2,xvar/yvar);
   rightTail=1-leftTail;
  }
//+------------------------------------------------------------------+
//| One-sample chi-square test                                       |
//| This test checks three hypotheses about the dispersion of the    |
//| given sample The following tests are performed:                  |
//|     * two-tailed test (null hypothesis - the dispersion equals   |
//|       the given number)                                          |
//|     * left-tailed test (null hypothesis - the dispersion is      |
//|       greater  than or equal to the given number)                |
//|     * right-tailed test (null hypothesis - dispersion is less    |
//|       than or equal to the given number).                        |
//| Test is based on the following assumptions:                      |
//|     * the given sample has a normal distribution.                |
//| Input parameters:                                                |
//|     X           -   sample 1. Array whose index goes from 0 to   |
//|                     N-1.                                         |
//|     N           -   size of the sample.                          |
//|     Variance    -   dispersion value to compare with.            |
//| Output parameters:                                               |
//|     BothTails   -   p-value for two-tailed test.                 |
//|                     If BothTails is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//|     LeftTail    -   p-value for left-tailed test.                |
//|                     If LeftTail is less than the given           |
//|                     significance level, the null hypothesis is   |
//|                     rejected.                                    |
//|     RightTail   -   p-value for right-tailed test.               |
//|                     If RightTail is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//+------------------------------------------------------------------+
static void CVarianceTests::OneSampleVarianceTest(const double &x[],
                                                  const int n,
                                                  const double variance,
                                                  double &bothTails,
                                                  double &leftTail,
                                                  double &rightTail)
  {
//--- create variables
   int    i;
   double xmean=0;
   double xvar=0;
   double s=0;
   double stat=0;
//--- check
   if(n<=1)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      //--- exit the function
      return;
     }
//--- Variance
   for(i=0;i<n;i++)
      xmean+=x[i];
   xmean=xmean/n;
//---
   for(i=0;i<n;i++)
      xvar+=CMath::Sqr(x[i]-xmean);
   xvar=xvar/(n-1);
//--- check
   if(xvar==0)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      //--- exit the function
      return;
     }
//--- Statistic
   stat=(n-1)*xvar/variance;
   s=CChiSquareDistr::ChiSquareDistribution(n-1,stat);
//--- get parameters
   bothTails=2*MathMin(s,1-s);
   leftTail=s;
   rightTail=1-leftTail;
  }
//+------------------------------------------------------------------+
//| Wilcoxon signed-rank test                                        |
//+------------------------------------------------------------------+
class CWilcoxonSignedRank
  {
private:
   static void       WCheb(const double x,const double c,double &tj,double &tj1,double &r);
   //--- calculation sigma
   static double     WSigma(const double s,const int n);
   static double     W5(const double s);
   static double     W6(const double s);
   static double     W7(const double s);
   static double     W8(const double s);
   static double     W9(const double s);
   static double     W10(const double s);
   static double     W11(const double s);
   static double     W12(const double s);
   static double     W13(const double s);
   static double     W14(const double s);
   static double     W15(const double s);
   static double     W16(const double s);
   static double     W17(const double s);
   static double     W18(const double s);
   static double     W19(const double s);
   static double     W20(const double s);
   static double     W21(const double s);
   static double     W22(const double s);
   static double     W23(const double s);
   static double     W24(const double s);
   static double     W25(const double s);
   static double     W26(const double s);
   static double     W27(const double s);
   static double     W28(const double s);
   static double     W29(const double s);
   static double     W30(const double s);
   static double     W40(const double s);
   static double     W60(const double s);
   static double     W120(const double s);
   static double     W200(const double s);
public:
   //--- constructor, destructor
                     CWilcoxonSignedRank(void);
                    ~CWilcoxonSignedRank(void);
   //--- check
   static void       WilcoxonSignedRankTest(const double &cx[],const int n,const double e,double &bothTails,double &leftTail,double &rightTail);
  };
//+------------------------------------------------------------------+
//| Constructor without parameters                                   |
//+------------------------------------------------------------------+
CWilcoxonSignedRank::CWilcoxonSignedRank(void)
  {

  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CWilcoxonSignedRank::~CWilcoxonSignedRank(void)
  {

  }
//+------------------------------------------------------------------+
//| Wilcoxon signed-rank test                                        |
//| This test checks three hypotheses about the median of the given  |
//| sample. The following tests are performed:                       |
//|     * two-tailed test (null hypothesis - the median is equal to  |
//|       the given value)                                           |
//|     * left-tailed test (null hypothesis - the median is greater  |
//|       than or equal to the given value)                          |
//|     * right-tailed test (null hypothesis - the median is less    |
//|       than or equal to the given value)                          |
//| Requirements:                                                    |
//|     * the scale of measurement should be ordinal, interval or    |
//|       ratio (i.e. the test could not be applied to nominal       |
//|       variables).                                                |
//|     * the distribution should be continuous and symmetric        |
//|       relative to its median.                                    |
//|     * number of distinct values in the X array should be greater |
//|       than 4                                                     |
//| The test is non-parametric and doesn't require distribution X to |
//| be normal                                                        |
//| Input parameters:                                                |
//|     X       -   sample. Array whose index goes from 0 to N-1.    |
//|     N       -   size of the sample.                              |
//|     Median  -   assumed median value.                            |
//| Output parameters:                                               |
//|     BothTails   -   p-value for two-tailed test.                 |
//|                     If BothTails is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//|     LeftTail    -   p-value for left-tailed test.                |
//|                     If LeftTail is less than the given           |
//|                     significance level, the null hypothesis is   |
//|                     rejected.                                    |
//|     RightTail   -   p-value for right-tailed test.               |
//|                     If RightTail is less than the given          |
//|                     significance level the null hypothesis is    |
//|                     rejected.                                    |
//| To calculate p-values, special approximation is used. This method|
//| lets us calculate p-values with two decimal places in interval   |
//| [0.0001, 1].                                                     |
//| "Two decimal places" does not sound very impressive, but in      |
//| practice the relative error of less than 1% is enough to make a  |
//| decision.                                                        |
//| There is no approximation outside the [0.0001, 1] interval.      |
//| Therefore, if the significance level outlies this interval, the  |
//| test returns 0.0001.                                             |
//+------------------------------------------------------------------+
static void CWilcoxonSignedRank::WilcoxonSignedRankTest(const double &cx[],
                                                        const int n,
                                                        const double e,
                                                        double &bothTails,
                                                        double &leftTail,
                                                        double &rightTail)
  {
//--- create variables
   int    i=0;
   int    j=0;
   int    k=0;
   int    t=0;
   double tmp=0;
   int    tmpi=0;
   int    ns=0;
   double r[];
   int    c[];
   double w=0;
   double p=0;
   double mp=0;
   double s=0;
   double sigma=0;
   double mu=0;
//--- create copy
   double x[];
   ArrayResizeAL(x,n);
   for(i=0;i<n;i++)
      x[i]=cx[i];
//--- Prepare
   if(n<5)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      //--- exit the function
      return;
     }
//--- calculation ns
   for(i=0;i<n;i++)
     {
      //--- check
      if(x[i]==e)
         continue;
      x[ns]=x[i];
      ns++;
     }
//--- check
   if(ns<5)
     {
      bothTails=1.0;
      leftTail=1.0;
      rightTail=1.0;
      //--- exit the function
      return;
     }
//--- allocation
   ArrayResizeAL(r,ns);
   ArrayResizeAL(c,ns);
   for(i=0;i<ns;i++)
     {
      r[i]=MathAbs(x[i]-e);
      c[i]=i;
     }
//--- sort {R, C}
   if(ns!=1)
     {
      i=2;
      //--- cycle
      do
        {
         t=i;
         //--- cycle
         while(t!=1)
           {
            k=t/2;
            //--- check
            if(r[k-1]>=r[t-1])
               t=1;
            else
              {
               //--- change values
               tmp=r[k-1];
               r[k-1]=r[t-1];
               r[t-1]=tmp;
               tmpi=c[k-1];
               c[k-1]=c[t-1];
               c[t-1]=tmpi;
               t=k;
              }
           }
         i++;
        }
      while(i<=ns);
      //--- change value
      i=ns-1;
      //--- cycle
      do
        {
         //--- change values
         tmp=r[i];
         r[i]=r[0];
         r[0]=tmp;
         tmpi=c[i];
         c[i]=c[0];
         c[0]=tmpi;
         t=1;
         //--- cycle
         while(t!=0)
           {
            k=2*t;
            //--- check
            if(k>i)
               t=0;
            else
              {
               //--- check
               if(k<i)
                 {
                  //--- check
                  if(r[k]>r[k-1])
                     k++;
                 }
               //--- check
               if(r[t-1]>=r[k-1])
                  t=0;
               else
                 {
                  //--- change values
                  tmp=r[k-1];
                  r[k-1]=r[t-1];
                  r[t-1]=tmp;
                  tmpi=c[k-1];
                  c[k-1]=c[t-1];
                  c[t-1]=tmpi;
                  t=k;
                 }
              }
           }
         i--;
        }
      while(i>=1);
     }
//--- compute tied ranks
   i=0;
   while(i<ns)
     {
      j=i+1;
      while(j<ns)
        {
         //--- check
         if(r[j]!=r[i])
            break;
         j++;
        }
      for(k=i;k<j;k++)
         r[k]=1+(double)(i+j-1)/2.0;
      i=j;
     }
//--- Compute W+
   w=0;
   for(i=0;i<ns;i++)
     {
      if(x[c[i]]>e)
         w+=r[i];
     }
//--- Result
   mu=(double)(ns*(ns+1))/4.0;
   sigma=MathSqrt((double)(ns*(ns+1)*(2*ns+1))/24.0);
   s=(w-mu)/sigma;
//--- check
   if(s<=0)
     {
      p=MathExp(WSigma(-((w-mu)/sigma),ns));
      mp=1-MathExp(WSigma(-((w-1-mu)/sigma),ns));
     }
   else
     {
      mp=MathExp(WSigma((w-mu)/sigma,ns));
      p=1-MathExp(WSigma((w+1-mu)/sigma,ns));
     }
//--- get parameters
   bothTails=MathMax(2*MathMin(p,mp),1.0E-4);
   leftTail=MathMax(p,1.0E-4);
   rightTail=MathMax(mp,1.0E-4);
  }
//+------------------------------------------------------------------+
//| Sequential Chebyshev interpolation.                              |
//+------------------------------------------------------------------+
static void CWilcoxonSignedRank::WCheb(const double x,const double c,
                                       double &tj,double &tj1,double &r)
  {
//--- create a variable
   double t;
//--- change values
   r+=c*tj;
   t=2*x*tj1-tj;
   tj=tj1;
   tj1=t;
  }
//+------------------------------------------------------------------+
//| Tail(S, 5)                                                       |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W5(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
   w=(int)MathRound(-(3.708099e+00*s)+7.500000e+00);
//--- check
   if(w>=7)
      r=-6.931e-01;
//--- check
   if(w==6)
      r=-9.008e-01;
//--- check
   if(w==5)
      r=-1.163e+00;
//--- check
   if(w==4)
      r=-1.520e+00;
//--- check
   if(w==3)
      r=-1.856e+00;
//--- check
   if(w==2)
      r=-2.367e+00;
//--- check
   if(w==1)
      r=-2.773e+00;
//--- check
   if(w<=0)
      r=-3.466e+00;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 6)                                                       |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W6(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(4.769696e+00*s)+1.050000e+01);
   if(w>=10)
      r=-6.931e-01;
//--- check
   if(w==9)
      r=-8.630e-01;
//--- check
   if(w==8)
      r=-1.068e+00;
//--- check
   if(w==7)
      r=-1.269e+00;
//--- check
   if(w==6)
      r=-1.520e+00;
//--- check
   if(w==5)
      r=-1.856e+00;
//--- check
   if(w==4)
      r=-2.213e+00;
//--- check
   if(w==3)
      r=-2.549e+00;
//--- check
   if(w==2)
      r=-3.060e+00;
//--- check
   if(w==1)
      r=-3.466e+00;
//--- check
   if(w<=0)
      r=-4.159e+00;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 7)                                                       |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W7(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(5.916080e+00*s)+1.400000e+01);
   if(w>=14)
      r=-6.325e-01;
//--- check
   if(w==13)
      r=-7.577e-01;
//--- check
   if(w==12)
      r=-9.008e-01;
//--- check
   if(w==11)
      r=-1.068e+00;
//--- check
   if(w==10)
      r=-1.241e+00;
//--- check
   if(w==9)
      r=-1.451e+00;
//--- check
   if(w==8)
      r=-1.674e+00;
//--- check
   if(w==7)
      r=-1.908e+00;
//--- check
   if(w==6)
      r=-2.213e+00;
//--- check
   if(w==5)
      r=-2.549e+00;
//--- check
   if(w==4)
      r=-2.906e+00;
//--- check
   if(w==3)
      r=-3.243e+00;
//--- check
   if(w==2)
      r=-3.753e+00;
//--- check
   if(w==1)
      r=-4.159e+00;
//--- check
   if(w<=0)
      r=-4.852e+00;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 8)                                                       |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W8(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(7.141428e+00*s)+1.800000e+01);
   if(w>=18)
      r=-6.399e-01;
//--- check
   if(w==17)
      r=-7.494e-01;
//--- check
   if(w==16)
      r=-8.630e-01;
//--- check
   if(w==15)
      r=-9.913e-01;
//--- check
   if(w==14)
      r=-1.138e+00;
//--- check
   if(w==13)
      r=-1.297e+00;
//--- check
   if(w==12)
      r=-1.468e+00;
//--- check
   if(w==11)
      r=-1.653e+00;
//--- check
   if(w==10)
      r=-1.856e+00;
//--- check
   if(w==9)
      r=-2.079e+00;
//--- check
   if(w==8)
      r=-2.326e+00;
//--- check
   if(w==7)
      r=-2.601e+00;
//--- check
   if(w==6)
      r=-2.906e+00;
//--- check
   if(w==5)
      r=-3.243e+00;
//--- check
   if(w==4)
      r=-3.599e+00;
//--- check
   if(w==3)
      r=-3.936e+00;
//--- check
   if(w==2)
      r=-4.447e+00;
//--- check
   if(w==1)
      r=-4.852e+00;
//--- check
   if(w<=0)
      r=-5.545e+00;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 9)                                                       |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W9(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(8.440972e+00*s)+2.250000e+01);
   if(w>=22)
      r=-6.931e-01;
//--- check
   if(w==21)
      r=-7.873e-01;
//--- check
   if(w==20)
      r=-8.912e-01;
//--- check
   if(w==19)
      r=-1.002e+00;
//--- check
   if(w==18)
      r=-1.120e+00;
//--- check
   if(w==17)
      r=-1.255e+00;
//--- check
   if(w==16)
      r=-1.394e+00;
//--- check
   if(w==15)
      r=-1.547e+00;
//--- check
   if(w==14)
      r=-1.717e+00;
//--- check
   if(w==13)
      r=-1.895e+00;
//--- check
   if(w==12)
      r=-2.079e+00;
//--- check
   if(w==11)
      r=-2.287e+00;
//--- check
   if(w==10)
      r=-2.501e+00;
//--- check
   if(w==9)
      r=-2.742e+00;
//--- check
   if(w==8)
      r=-3.019e+00;
//--- check
   if(w==7)
      r=-3.294e+00;
//--- check
   if(w==6)
      r=-3.599e+00;
//--- check
   if(w==5)
      r=-3.936e+00;
//--- check
   if(w==4)
      r=-4.292e+00;
//--- check
   if(w==3)
      r=-4.629e+00;
//--- check
   if(w==2)
      r=-5.140e+00;
//--- check
   if(w==1)
      r=-5.545e+00;
//--- check
   if(w<=0)
      r=-6.238e+00;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 10)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W10(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(9.810708e+00*s)+2.750000e+01);
   if(w>=27)
      r=-6.931e-01;
//--- check
   if(w==26)
      r=-7.745e-01;
//--- check
   if(w==25)
      r=-8.607e-01;
//--- check
   if(w==24)
      r=-9.551e-01;
//--- check
   if(w==23)
      r=-1.057e+00;
//--- check
   if(w==22)
      r=-1.163e+00;
//--- check
   if(w==21)
      r=-1.279e+00;
//--- check
   if(w==20)
      r=-1.402e+00;
//--- check
   if(w==19)
      r=-1.533e+00;
//--- check
   if(w==18)
      r=-1.674e+00;
//--- check
   if(w==17)
      r=-1.826e+00;
//--- check
   if(w==16)
      r=-1.983e+00;
//--- check
   if(w==15)
      r=-2.152e+00;
//--- check
   if(w==14)
      r=-2.336e+00;
//--- check
   if(w==13)
      r=-2.525e+00;
//--- check
   if(w==12)
      r=-2.727e+00;
//--- check
   if(w==11)
      r=-2.942e+00;
//--- check
   if(w==10)
      r=-3.170e+00;
//--- check
   if(w==9)
      r=-3.435e+00;
//--- check
   if(w==8)
      r=-3.713e+00;
//--- check
   if(w==7)
      r=-3.987e+00;
//--- check
   if(w==6)
      r=-4.292e+00;
//--- check
   if(w==5)
      r=-4.629e+00;
//--- check
   if(w==4)
      r=-4.986e+00;
//--- check
   if(w==3)
      r=-5.322e+00;
//--- check
   if(w==2)
      r=-5.833e+00;
//--- check
   if(w==1)
      r=-6.238e+00;
//--- check
   if(w<=0)
      r=-6.931e+00;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 11)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W11(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(1.124722e+01*s)+3.300000e+01);
   if(w>=33)
      r=-6.595e-01;
//--- check
   if(w==32)
      r=-7.279e-01;
//--- check
   if(w==31)
      r=-8.002e-01;
//--- check
   if(w==30)
      r=-8.782e-01;
//--- check
   if(w==29)
      r=-9.615e-01;
//--- check
   if(w==28)
      r=-1.050e+00;
//--- check
   if(w==27)
      r=-1.143e+00;
//--- check
   if(w==26)
      r=-1.243e+00;
//--- check
   if(w==25)
      r=-1.348e+00;
//--- check
   if(w==24)
      r=-1.459e+00;
//--- check
   if(w==23)
      r=-1.577e+00;
//--- check
   if(w==22)
      r=-1.700e+00;
//--- check
   if(w==21)
      r=-1.832e+00;
//--- check
   if(w==20)
      r=-1.972e+00;
//--- check
   if(w==19)
      r=-2.119e+00;
//--- check
   if(w==18)
      r=-2.273e+00;
//--- check
   if(w==17)
      r=-2.437e+00;
//--- check
   if(w==16)
      r=-2.607e+00;
//--- check
   if(w==15)
      r=-2.788e+00;
//--- check
   if(w==14)
      r=-2.980e+00;
//--- check
   if(w==13)
      r=-3.182e+00;
//--- check
   if(w==12)
      r=-3.391e+00;
//--- check
   if(w==11)
      r=-3.617e+00;
//--- check
   if(w==10)
      r=-3.863e+00;
//--- check
   if(w==9)
      r=-4.128e+00;
//--- check
   if(w==8)
      r=-4.406e+00;
//--- check
   if(w==7)
      r=-4.680e+00;
//--- check
   if(w==6)
      r=-4.986e+00;
//--- check
   if(w==5)
      r=-5.322e+00;
//--- check
   if(w==4)
      r=-5.679e+00;
//--- check
   if(w==3)
      r=-6.015e+00;
//--- check
   if(w==2)
      r=-6.526e+00;
//--- check
   if(w==1)
      r=-6.931e+00;
//--- check
   if(w<=0)
      r=-7.625e+00;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 12)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W12(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(1.274755e+01*s)+3.900000e+01);
   if(w>=39)
      r=-6.633e-01;
//--- check
   if(w==38)
      r=-7.239e-01;
//--- check
   if(w==37)
      r=-7.878e-01;
//--- check
   if(w==36)
      r=-8.556e-01;
//--- check
   if(w==35)
      r=-9.276e-01;
//--- check
   if(w==34)
      r=-1.003e+00;
//--- check
   if(w==33)
      r=-1.083e+00;
//--- check
   if(w==32)
      r=-1.168e+00;
//--- check
   if(w==31)
      r=-1.256e+00;
//--- check
   if(w==30)
      r=-1.350e+00;
//--- check
   if(w==29)
      r=-1.449e+00;
//--- check
   if(w==28)
      r=-1.552e+00;
//--- check
   if(w==27)
      r=-1.660e+00;
//--- check
   if(w==26)
      r=-1.774e+00;
//--- check
   if(w==25)
      r=-1.893e+00;
//--- check
   if(w==24)
      r=-2.017e+00;
//--- check
   if(w==23)
      r=-2.148e+00;
//--- check
   if(w==22)
      r=-2.285e+00;
//--- check
   if(w==21)
      r=-2.429e+00;
//--- check
   if(w==20)
      r=-2.581e+00;
//--- check
   if(w==19)
      r=-2.738e+00;
//--- check
   if(w==18)
      r=-2.902e+00;
//--- check
   if(w==17)
      r=-3.076e+00;
//--- check
   if(w==16)
      r=-3.255e+00;
//--- check
   if(w==15)
      r=-3.443e+00;
//--- check
   if(w==14)
      r=-3.645e+00;
//--- check
   if(w==13)
      r=-3.852e+00;
//--- check
   if(w==12)
      r=-4.069e+00;
//--- check
   if(w==11)
      r=-4.310e+00;
//--- check
   if(w==10)
      r=-4.557e+00;
//--- check
   if(w==9)
      r=-4.821e+00;
//--- check
   if(w==8)
      r=-5.099e+00;
//--- check
   if(w==7)
      r=-5.373e+00;
//--- check
   if(w==6)
      r=-5.679e+00;
//--- check
   if(w==5)
      r=-6.015e+00;
//--- check
   if(w==4)
      r=-6.372e+00;
//--- check
   if(w==3)
      r=-6.708e+00;
//--- check
   if(w==2)
      r=-7.219e+00;
//--- check
   if(w==1)
      r=-7.625e+00;
//--- check
   if(w<=0)
      r=-8.318e+00;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 13)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W13(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(1.430909e+01*s)+4.550000e+01);
   if(w>=45)
      r=-6.931e-01;
//--- check
   if(w==44)
      r=-7.486e-01;
//--- check
   if(w==43)
      r=-8.068e-01;
//--- check
   if(w==42)
      r=-8.683e-01;
//--- check
   if(w==41)
      r=-9.328e-01;
//--- check
   if(w==40)
      r=-1.001e+00;
//--- check
   if(w==39)
      r=-1.072e+00;
//--- check
   if(w==38)
      r=-1.146e+00;
//--- check
   if(w==37)
      r=-1.224e+00;
//--- check
   if(w==36)
      r=-1.306e+00;
//--- check
   if(w==35)
      r=-1.392e+00;
//--- check
   if(w==34)
      r=-1.481e+00;
//--- check
   if(w==33)
      r=-1.574e+00;
//--- check
   if(w==32)
      r=-1.672e+00;
//--- check
   if(w==31)
      r=-1.773e+00;
//--- check
   if(w==30)
      r=-1.879e+00;
//--- check
   if(w==29)
      r=-1.990e+00;
//--- check
   if(w==28)
      r=-2.104e+00;
//--- check
   if(w==27)
      r=-2.224e+00;
//--- check
   if(w==26)
      r=-2.349e+00;
//--- check
   if(w==25)
      r=-2.479e+00;
//--- check
   if(w==24)
      r=-2.614e+00;
//--- check
   if(w==23)
      r=-2.755e+00;
//--- check
   if(w==22)
      r=-2.902e+00;
//--- check
   if(w==21)
      r=-3.055e+00;
//--- check
   if(w==20)
      r=-3.215e+00;
//--- check
   if(w==19)
      r=-3.380e+00;
//--- check
   if(w==18)
      r=-3.551e+00;
//--- check
   if(w==17)
      r=-3.733e+00;
//--- check
   if(w==16)
      r=-3.917e+00;
//--- check
   if(w==15)
      r=-4.113e+00;
//--- check
   if(w==14)
      r=-4.320e+00;
//--- check
   if(w==13)
      r=-4.534e+00;
//--- check
   if(w==12)
      r=-4.762e+00;
//--- check
   if(w==11)
      r=-5.004e+00;
//--- check
   if(w==10)
      r=-5.250e+00;
//--- check
   if(w==9)
      r=-5.514e+00;
//--- check
   if(w==8)
      r=-5.792e+00;
//--- check
   if(w==7)
      r=-6.066e+00;
//--- check
   if(w==6)
      r=-6.372e+00;
//--- check
   if(w==5)
      r=-6.708e+00;
//--- check
   if(w==4)
      r=-7.065e+00;
//--- check
   if(w==3)
      r=-7.401e+00;
//--- check
   if(w==2)
      r=-7.912e+00;
//--- check
   if(w==1)
      r=-8.318e+00;
//--- check
   if(w<=0)
      r=-9.011e+00;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 14)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W14(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(1.592953e+01*s)+5.250000e+01);
   if(w>=52)
      r=-6.931e-01;
//--- check
   if(w==51)
      r=-7.428e-01;
//--- check
   if(w==50)
      r=-7.950e-01;
//--- check
   if(w==49)
      r=-8.495e-01;
//--- check
   if(w==48)
      r=-9.067e-01;
//--- check
   if(w==47)
      r=-9.664e-01;
//--- check
   if(w==46)
      r=-1.029e+00;
//--- check
   if(w==45)
      r=-1.094e+00;
//--- check
   if(w==44)
      r=-1.162e+00;
//--- check
   if(w==43)
      r=-1.233e+00;
//--- check
   if(w==42)
      r=-1.306e+00;
//--- check
   if(w==41)
      r=-1.383e+00;
//--- check
   if(w==40)
      r=-1.463e+00;
//--- check
   if(w==39)
      r=-1.546e+00;
//--- check
   if(w==38)
      r=-1.632e+00;
//--- check
   if(w==37)
      r=-1.722e+00;
//--- check
   if(w==36)
      r=-1.815e+00;
//--- check
   if(w==35)
      r=-1.911e+00;
//--- check
   if(w==34)
      r=-2.011e+00;
//--- check
   if(w==33)
      r=-2.115e+00;
//--- check
   if(w==32)
      r=-2.223e+00;
//--- check
   if(w==31)
      r=-2.334e+00;
//--- check
   if(w==30)
      r=-2.450e+00;
//--- check
   if(w==29)
      r=-2.570e+00;
//--- check
   if(w==28)
      r=-2.694e+00;
//--- check
   if(w==27)
      r=-2.823e+00;
//--- check
   if(w==26)
      r=-2.956e+00;
//--- check
   if(w==25)
      r=-3.095e+00;
//--- check
   if(w==24)
      r=-3.238e+00;
//--- check
   if(w==23)
      r=-3.387e+00;
//--- check
   if(w==22)
      r=-3.541e+00;
//--- check
   if(w==21)
      r=-3.700e+00;
//--- check
   if(w==20)
      r=-3.866e+00;
//--- check
   if(w==19)
      r=-4.038e+00;
//--- check
   if(w==18)
      r=-4.215e+00;
//--- check
   if(w==17)
      r=-4.401e+00;
//--- check
   if(w==16)
      r=-4.592e+00;
//--- check
   if(w==15)
      r=-4.791e+00;
//--- check
   if(w==14)
      r=-5.004e+00;
//--- check
   if(w==13)
      r=-5.227e+00;
//--- check
   if(w==12)
      r=-5.456e+00;
//--- check
   if(w==11)
      r=-5.697e+00;
//--- check
   if(w==10)
      r=-5.943e+00;
//--- check
   if(w==9)
      r=-6.208e+00;
//--- check
   if(w==8)
      r=-6.485e+00;
//--- check
   if(w==7)
      r=-6.760e+00;
//--- check
   if(w==6)
      r=-7.065e+00;
//--- check
   if(w==5)
      r=-7.401e+00;
//--- check
   if(w==4)
      r=-7.758e+00;
//--- check
   if(w==3)
      r=-8.095e+00;
//--- check
   if(w==2)
      r=-8.605e+00;
//--- check
   if(w==1)
      r=-9.011e+00;
//--- check
   if(w<=0)
      r=-9.704e+00;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 15)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W15(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(1.760682e+01*s)+6.000000e+01);
   if(w>=60)
      r=-6.714e-01;
//--- check
   if(w==59)
      r=-7.154e-01;
//--- check
   if(w==58)
      r=-7.613e-01;
//--- check
   if(w==57)
      r=-8.093e-01;
//--- check
   if(w==56)
      r=-8.593e-01;
//--- check
   if(w==55)
      r=-9.114e-01;
//--- check
   if(w==54)
      r=-9.656e-01;
//--- check
   if(w==53)
      r=-1.022e+00;
//--- check
   if(w==52)
      r=-1.081e+00;
//--- check
   if(w==51)
      r=-1.142e+00;
//--- check
   if(w==50)
      r=-1.205e+00;
//--- check
   if(w==49)
      r=-1.270e+00;
//--- check
   if(w==48)
      r=-1.339e+00;
//--- check
   if(w==47)
      r=-1.409e+00;
//--- check
   if(w==46)
      r=-1.482e+00;
//--- check
   if(w==45)
      r=-1.558e+00;
//--- check
   if(w==44)
      r=-1.636e+00;
//--- check
   if(w==43)
      r=-1.717e+00;
//--- check
   if(w==42)
      r=-1.801e+00;
//--- check
   if(w==41)
      r=-1.888e+00;
//--- check
   if(w==40)
      r=-1.977e+00;
//--- check
   if(w==39)
      r=-2.070e+00;
//--- check
   if(w==38)
      r=-2.166e+00;
//--- check
   if(w==37)
      r=-2.265e+00;
//--- check
   if(w==36)
      r=-2.366e+00;
//--- check
   if(w==35)
      r=-2.472e+00;
//--- check
   if(w==34)
      r=-2.581e+00;
//--- check
   if(w==33)
      r=-2.693e+00;
//--- check
   if(w==32)
      r=-2.809e+00;
//--- check
   if(w==31)
      r=-2.928e+00;
//--- check
   if(w==30)
      r=-3.051e+00;
//--- check
   if(w==29)
      r=-3.179e+00;
//--- check
   if(w==28)
      r=-3.310e+00;
//--- check
   if(w==27)
      r=-3.446e+00;
//--- check
   if(w==26)
      r=-3.587e+00;
//--- check
   if(w==25)
      r=-3.732e+00;
//--- check
   if(w==24)
      r=-3.881e+00;
//--- check
   if(w==23)
      r=-4.036e+00;
//--- check
   if(w==22)
      r=-4.195e+00;
//--- check
   if(w==21)
      r=-4.359e+00;
//--- check
   if(w==20)
      r=-4.531e+00;
//--- check
   if(w==19)
      r=-4.707e+00;
//--- check
   if(w==18)
      r=-4.888e+00;
//--- check
   if(w==17)
      r=-5.079e+00;
//--- check
   if(w==16)
      r=-5.273e+00;
//--- check
   if(w==15)
      r=-5.477e+00;
//--- check
   if(w==14)
      r=-5.697e+00;
//--- check
   if(w==13)
      r=-5.920e+00;
//--- check
   if(w==12)
      r=-6.149e+00;
//--- check
   if(w==11)
      r=-6.390e+00;
//--- check
   if(w==10)
      r=-6.636e+00;
//--- check
   if(w==9)
      r=-6.901e+00;
//--- check
   if(w==8)
      r=-7.178e+00;
//--- check
   if(w==7)
      r=-7.453e+00;
//--- check
   if(w==6)
      r=-7.758e+00;
//--- check
   if(w==5)
      r=-8.095e+00;
//--- check
   if(w==4)
      r=-8.451e+00;
//--- check
   if(w==3)
      r=-8.788e+00;
//--- check
   if(w==2)
      r=-9.299e+00;
//--- check
   if(w==1)
      r=-9.704e+00;
//--- check
   if(w<=0)
      r=-1.040e+01;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 16)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W16(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(1.933908e+01*s)+6.800000e+01);
   if(w>=68)
      r=-6.733e-01;
//--- check
   if(w==67)
      r=-7.134e-01;
//--- check
   if(w==66)
      r=-7.551e-01;
//--- check
   if(w==65)
      r=-7.986e-01;
//--- check
   if(w==64)
      r=-8.437e-01;
//--- check
   if(w==63)
      r=-8.905e-01;
//--- check
   if(w==62)
      r=-9.391e-01;
//--- check
   if(w==61)
      r=-9.895e-01;
//--- check
   if(w==60)
      r=-1.042e+00;
//--- check
   if(w==59)
      r=-1.096e+00;
//--- check
   if(w==58)
      r=-1.152e+00;
//--- check
   if(w==57)
      r=-1.210e+00;
//--- check
   if(w==56)
      r=-1.270e+00;
//--- check
   if(w==55)
      r=-1.331e+00;
//--- check
   if(w==54)
      r=-1.395e+00;
//--- check
   if(w==53)
      r=-1.462e+00;
//--- check
   if(w==52)
      r=-1.530e+00;
//--- check
   if(w==51)
      r=-1.600e+00;
//--- check
   if(w==50)
      r=-1.673e+00;
//--- check
   if(w==49)
      r=-1.748e+00;
//--- check
   if(w==48)
      r=-1.825e+00;
//--- check
   if(w==47)
      r=-1.904e+00;
//--- check
   if(w==46)
      r=-1.986e+00;
//--- check
   if(w==45)
      r=-2.071e+00;
//--- check
   if(w==44)
      r=-2.158e+00;
//--- check
   if(w==43)
      r=-2.247e+00;
//--- check
   if(w==42)
      r=-2.339e+00;
//--- check
   if(w==41)
      r=-2.434e+00;
//--- check
   if(w==40)
      r=-2.532e+00;
//--- check
   if(w==39)
      r=-2.632e+00;
//--- check
   if(w==38)
      r=-2.735e+00;
//--- check
   if(w==37)
      r=-2.842e+00;
//--- check
   if(w==36)
      r=-2.951e+00;
//--- check
   if(w==35)
      r=-3.064e+00;
//--- check
   if(w==34)
      r=-3.179e+00;
//--- check
   if(w==33)
      r=-3.298e+00;
//--- check
   if(w==32)
      r=-3.420e+00;
//--- check
   if(w==31)
      r=-3.546e+00;
//--- check
   if(w==30)
      r=-3.676e+00;
//--- check
   if(w==29)
      r=-3.810e+00;
//--- check
   if(w==28)
      r=-3.947e+00;
//--- check
   if(w==27)
      r=-4.088e+00;
//--- check
   if(w==26)
      r=-4.234e+00;
//--- check
   if(w==25)
      r=-4.383e+00;
//--- check
   if(w==24)
      r=-4.538e+00;
//--- check
   if(w==23)
      r=-4.697e+00;
//--- check
   if(w==22)
      r=-4.860e+00;
//--- check
   if(w==21)
      r=-5.029e+00;
//--- check
   if(w==20)
      r=-5.204e+00;
//--- check
   if(w==19)
      r=-5.383e+00;
//--- check
   if(w==18)
      r=-5.569e+00;
//--- check
   if(w==17)
      r=-5.762e+00;
//--- check
   if(w==16)
      r=-5.960e+00;
//--- check
   if(w==15)
      r=-6.170e+00;
//--- check
   if(w==14)
      r=-6.390e+00;
//--- check
   if(w==13)
      r=-6.613e+00;
//--- check
   if(w==12)
      r=-6.842e+00;
//--- check
   if(w==11)
      r=-7.083e+00;
//--- check
   if(w==10)
      r=-7.329e+00;
//--- check
   if(w==9)
      r=-7.594e+00;
//--- check
   if(w==8)
      r=-7.871e+00;
//--- check
   if(w==7)
      r=-8.146e+00;
//--- check
   if(w==6)
      r=-8.451e+00;
//--- check
   if(w==5)
      r=-8.788e+00;
//--- check
   if(w==4)
      r=-9.144e+00;
//--- check
   if(w==3)
      r=-9.481e+00;
//--- check
   if(w==2)
      r=-9.992e+00;
//--- check
   if(w==1)
      r=-1.040e+01;
//--- check
   if(w<=0)
      r=-1.109e+01;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 17)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W17(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(2.112463e+01*s)+7.650000e+01);
   if(w>=76)
      r=-6.931e-01;
//--- check
   if(w==75)
      r=-7.306e-01;
//--- check
   if(w==74)
      r=-7.695e-01;
//--- check
   if(w==73)
      r=-8.097e-01;
//--- check
   if(w==72)
      r=-8.514e-01;
//--- check
   if(w==71)
      r=-8.946e-01;
//--- check
   if(w==70)
      r=-9.392e-01;
//--- check
   if(w==69)
      r=-9.853e-01;
//--- check
   if(w==68)
      r=-1.033e+00;
//--- check
   if(w==67)
      r=-1.082e+00;
//--- check
   if(w==66)
      r=-1.133e+00;
//--- check
   if(w==65)
      r=-1.185e+00;
//--- check
   if(w==64)
      r=-1.240e+00;
//--- check
   if(w==63)
      r=-1.295e+00;
//--- check
   if(w==62)
      r=-1.353e+00;
//--- check
   if(w==61)
      r=-1.412e+00;
//--- check
   if(w==60)
      r=-1.473e+00;
//--- check
   if(w==59)
      r=-1.536e+00;
//--- check
   if(w==58)
      r=-1.600e+00;
//--- check
   if(w==57)
      r=-1.666e+00;
//--- check
   if(w==56)
      r=-1.735e+00;
//--- check
   if(w==55)
      r=-1.805e+00;
//--- check
   if(w==54)
      r=-1.877e+00;
//--- check
   if(w==53)
      r=-1.951e+00;
//--- check
   if(w==52)
      r=-2.028e+00;
//--- check
   if(w==51)
      r=-2.106e+00;
//--- check
   if(w==50)
      r=-2.186e+00;
//--- check
   if(w==49)
      r=-2.269e+00;
//--- check
   if(w==48)
      r=-2.353e+00;
//--- check
   if(w==47)
      r=-2.440e+00;
//--- check
   if(w==46)
      r=-2.530e+00;
//--- check
   if(w==45)
      r=-2.621e+00;
//--- check
   if(w==44)
      r=-2.715e+00;
//--- check
   if(w==43)
      r=-2.812e+00;
//--- check
   if(w==42)
      r=-2.911e+00;
//--- check
   if(w==41)
      r=-3.012e+00;
//--- check
   if(w==40)
      r=-3.116e+00;
//--- check
   if(w==39)
      r=-3.223e+00;
//--- check
   if(w==38)
      r=-3.332e+00;
//--- check
   if(w==37)
      r=-3.445e+00;
//--- check
   if(w==36)
      r=-3.560e+00;
//--- check
   if(w==35)
      r=-3.678e+00;
//--- check
   if(w==34)
      r=-3.799e+00;
//--- check
   if(w==33)
      r=-3.924e+00;
//--- check
   if(w==32)
      r=-4.052e+00;
//--- check
   if(w==31)
      r=-4.183e+00;
//--- check
   if(w==30)
      r=-4.317e+00;
//--- check
   if(w==29)
      r=-4.456e+00;
//--- check
   if(w==28)
      r=-4.597e+00;
//--- check
   if(w==27)
      r=-4.743e+00;
//--- check
   if(w==26)
      r=-4.893e+00;
//--- check
   if(w==25)
      r=-5.047e+00;
//--- check
   if(w==24)
      r=-5.204e+00;
//--- check
   if(w==23)
      r=-5.367e+00;
//--- check
   if(w==22)
      r=-5.534e+00;
//--- check
   if(w==21)
      r=-5.706e+00;
//--- check
   if(w==20)
      r=-5.884e+00;
//--- check
   if(w==19)
      r=-6.066e+00;
//--- check
   if(w==18)
      r=-6.254e+00;
//--- check
   if(w==17)
      r=-6.451e+00;
//--- check
   if(w==16)
      r=-6.654e+00;
//--- check
   if(w==15)
      r=-6.864e+00;
//--- check
   if(w==14)
      r=-7.083e+00;
//--- check
   if(w==13)
      r=-7.306e+00;
//--- check
   if(w==12)
      r=-7.535e+00;
//--- check
   if(w==11)
      r=-7.776e+00;
//--- check
   if(w==10)
      r=-8.022e+00;
//--- check
   if(w==9)
      r=-8.287e+00;
//--- check
   if(w==8)
      r=-8.565e+00;
//--- check
   if(w==7)
      r=-8.839e+00;
//--- check
   if(w==6)
      r=-9.144e+00;
//--- check
   if(w==5)
      r=-9.481e+00;
//--- check
   if(w==4)
      r=-9.838e+00;
//--- check
   if(w==3)
      r=-1.017e+01;
//--- check
   if(w==2)
      r=-1.068e+01;
//--- check
   if(w==1)
      r=-1.109e+01;
//--- check
   if(w<=0)
      r=-1.178e+01;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 18)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W18(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(2.296193e+01*s)+8.550000e+01);
   if(w>=85)
      r=-6.931e-01;
//--- check
   if(w==84)
      r=-7.276e-01;
//--- check
   if(w==83)
      r=-7.633e-01;
//--- check
   if(w==82)
      r=-8.001e-01;
//--- check
   if(w==81)
      r=-8.381e-01;
//--- check
   if(w==80)
      r=-8.774e-01;
//--- check
   if(w==79)
      r=-9.179e-01;
//--- check
   if(w==78)
      r=-9.597e-01;
//--- check
   if(w==77)
      r=-1.003e+00;
//--- check
   if(w==76)
      r=-1.047e+00;
//--- check
   if(w==75)
      r=-1.093e+00;
//--- check
   if(w==74)
      r=-1.140e+00;
//--- check
   if(w==73)
      r=-1.188e+00;
//--- check
   if(w==72)
      r=-1.238e+00;
//--- check
   if(w==71)
      r=-1.289e+00;
//--- check
   if(w==70)
      r=-1.342e+00;
//--- check
   if(w==69)
      r=-1.396e+00;
//--- check
   if(w==68)
      r=-1.452e+00;
//--- check
   if(w==67)
      r=-1.509e+00;
//--- check
   if(w==66)
      r=-1.568e+00;
//--- check
   if(w==65)
      r=-1.628e+00;
//--- check
   if(w==64)
      r=-1.690e+00;
//--- check
   if(w==63)
      r=-1.753e+00;
//--- check
   if(w==62)
      r=-1.818e+00;
//--- check
   if(w==61)
      r=-1.885e+00;
//--- check
   if(w==60)
      r=-1.953e+00;
//--- check
   if(w==59)
      r=-2.023e+00;
//--- check
   if(w==58)
      r=-2.095e+00;
//--- check
   if(w==57)
      r=-2.168e+00;
//--- check
   if(w==56)
      r=-2.244e+00;
//--- check
   if(w==55)
      r=-2.321e+00;
//--- check
   if(w==54)
      r=-2.400e+00;
//--- check
   if(w==53)
      r=-2.481e+00;
//--- check
   if(w==52)
      r=-2.564e+00;
//--- check
   if(w==51)
      r=-2.648e+00;
//--- check
   if(w==50)
      r=-2.735e+00;
//--- check
   if(w==49)
      r=-2.824e+00;
//--- check
   if(w==48)
      r=-2.915e+00;
//--- check
   if(w==47)
      r=-3.008e+00;
//--- check
   if(w==46)
      r=-3.104e+00;
//--- check
   if(w==45)
      r=-3.201e+00;
//--- check
   if(w==44)
      r=-3.301e+00;
//--- check
   if(w==43)
      r=-3.403e+00;
//--- check
   if(w==42)
      r=-3.508e+00;
//--- check
   if(w==41)
      r=-3.615e+00;
//--- check
   if(w==40)
      r=-3.724e+00;
//--- check
   if(w==39)
      r=-3.836e+00;
//--- check
   if(w==38)
      r=-3.950e+00;
//--- check
   if(w==37)
      r=-4.068e+00;
//--- check
   if(w==36)
      r=-4.188e+00;
//--- check
   if(w==35)
      r=-4.311e+00;
//--- check
   if(w==34)
      r=-4.437e+00;
//--- check
   if(w==33)
      r=-4.565e+00;
//--- check
   if(w==32)
      r=-4.698e+00;
//--- check
   if(w==31)
      r=-4.833e+00;
//--- check
   if(w==30)
      r=-4.971e+00;
//--- check
   if(w==29)
      r=-5.113e+00;
//--- check
   if(w==28)
      r=-5.258e+00;
//--- check
   if(w==27)
      r=-5.408e+00;
//--- check
   if(w==26)
      r=-5.561e+00;
//--- check
   if(w==25)
      r=-5.717e+00;
//--- check
   if(w==24)
      r=-5.878e+00;
//--- check
   if(w==23)
      r=-6.044e+00;
//--- check
   if(w==22)
      r=-6.213e+00;
//--- check
   if(w==21)
      r=-6.388e+00;
//--- check
   if(w==20)
      r=-6.569e+00;
//--- check
   if(w==19)
      r=-6.753e+00;
//--- check
   if(w==18)
      r=-6.943e+00;
//--- check
   if(w==17)
      r=-7.144e+00;
//--- check
   if(w==16)
      r=-7.347e+00;
//--- check
   if(w==15)
      r=-7.557e+00;
//--- check
   if(w==14)
      r=-7.776e+00;
//--- check
   if(w==13)
      r=-7.999e+00;
//--- check
   if(w==12)
      r=-8.228e+00;
//--- check
   if(w==11)
      r=-8.469e+00;
//--- check
   if(w==10)
      r=-8.715e+00;
//--- check
   if(w==9)
      r=-8.980e+00;
//--- check
   if(w==8)
      r=-9.258e+00;
//--- check
   if(w==7)
      r=-9.532e+00;
//--- check
   if(w==6)
      r=-9.838e+00;
//--- check
   if(w==5)
      r=-1.017e+01;
//--- check
   if(w==4)
      r=-1.053e+01;
//--- check
   if(w==3)
      r=-1.087e+01;
//--- check
   if(w==2)
      r=-1.138e+01;
//--- check
   if(w==1)
      r=-1.178e+01;
//--- check
   if(w<=0)
      r=-1.248e+01;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 19)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W19(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(2.484955e+01*s)+9.500000e+01);
   if(w>=95)
      r=-6.776e-01;
//--- check
   if(w==94)
      r=-7.089e-01;
//--- check
   if(w==93)
      r=-7.413e-01;
//--- check
   if(w==92)
      r=-7.747e-01;
//--- check
   if(w==91)
      r=-8.090e-01;
//--- check
   if(w==90)
      r=-8.445e-01;
//--- check
   if(w==89)
      r=-8.809e-01;
//--- check
   if(w==88)
      r=-9.185e-01;
//--- check
   if(w==87)
      r=-9.571e-01;
//--- check
   if(w==86)
      r=-9.968e-01;
//--- check
   if(w==85)
      r=-1.038e+00;
//--- check
   if(w==84)
      r=-1.080e+00;
//--- check
   if(w==83)
      r=-1.123e+00;
//--- check
   if(w==82)
      r=-1.167e+00;
//--- check
   if(w==81)
      r=-1.213e+00;
//--- check
   if(w==80)
      r=-1.259e+00;
//--- check
   if(w==79)
      r=-1.307e+00;
//--- check
   if(w==78)
      r=-1.356e+00;
//--- check
   if(w==77)
      r=-1.407e+00;
//--- check
   if(w==76)
      r=-1.458e+00;
//--- check
   if(w==75)
      r=-1.511e+00;
//--- check
   if(w==74)
      r=-1.565e+00;
//--- check
   if(w==73)
      r=-1.621e+00;
//--- check
   if(w==72)
      r=-1.678e+00;
//--- check
   if(w==71)
      r=-1.736e+00;
//--- check
   if(w==70)
      r=-1.796e+00;
//--- check
   if(w==69)
      r=-1.857e+00;
//--- check
   if(w==68)
      r=-1.919e+00;
//--- check
   if(w==67)
      r=-1.983e+00;
//--- check
   if(w==66)
      r=-2.048e+00;
//--- check
   if(w==65)
      r=-2.115e+00;
//--- check
   if(w==64)
      r=-2.183e+00;
//--- check
   if(w==63)
      r=-2.253e+00;
//--- check
   if(w==62)
      r=-2.325e+00;
//--- check
   if(w==61)
      r=-2.398e+00;
//--- check
   if(w==60)
      r=-2.472e+00;
//--- check
   if(w==59)
      r=-2.548e+00;
//--- check
   if(w==58)
      r=-2.626e+00;
//--- check
   if(w==57)
      r=-2.706e+00;
//--- check
   if(w==56)
      r=-2.787e+00;
//--- check
   if(w==55)
      r=-2.870e+00;
//--- check
   if(w==54)
      r=-2.955e+00;
//--- check
   if(w==53)
      r=-3.042e+00;
//--- check
   if(w==52)
      r=-3.130e+00;
//--- check
   if(w==51)
      r=-3.220e+00;
//--- check
   if(w==50)
      r=-3.313e+00;
//--- check
   if(w==49)
      r=-3.407e+00;
//--- check
   if(w==48)
      r=-3.503e+00;
//--- check
   if(w==47)
      r=-3.601e+00;
//--- check
   if(w==46)
      r=-3.702e+00;
//--- check
   if(w==45)
      r=-3.804e+00;
//--- check
   if(w==44)
      r=-3.909e+00;
//--- check
   if(w==43)
      r=-4.015e+00;
//--- check
   if(w==42)
      r=-4.125e+00;
//--- check
   if(w==41)
      r=-4.236e+00;
//--- check
   if(w==40)
      r=-4.350e+00;
//--- check
   if(w==39)
      r=-4.466e+00;
//--- check
   if(w==38)
      r=-4.585e+00;
//--- check
   if(w==37)
      r=-4.706e+00;
//--- check
   if(w==36)
      r=-4.830e+00;
//--- check
   if(w==35)
      r=-4.957e+00;
//--- check
   if(w==34)
      r=-5.086e+00;
//--- check
   if(w==33)
      r=-5.219e+00;
//--- check
   if(w==32)
      r=-5.355e+00;
//--- check
   if(w==31)
      r=-5.493e+00;
//--- check
   if(w==30)
      r=-5.634e+00;
//--- check
   if(w==29)
      r=-5.780e+00;
//--- check
   if(w==28)
      r=-5.928e+00;
//--- check
   if(w==27)
      r=-6.080e+00;
//--- check
   if(w==26)
      r=-6.235e+00;
//--- check
   if(w==25)
      r=-6.394e+00;
//--- check
   if(w==24)
      r=-6.558e+00;
//--- check
   if(w==23)
      r=-6.726e+00;
//--- check
   if(w==22)
      r=-6.897e+00;
//--- check
   if(w==21)
      r=-7.074e+00;
//--- check
   if(w==20)
      r=-7.256e+00;
//--- check
   if(w==19)
      r=-7.443e+00;
//--- check
   if(w==18)
      r=-7.636e+00;
//--- check
   if(w==17)
      r=-7.837e+00;
//--- check
   if(w==16)
      r=-8.040e+00;
//--- check
   if(w==15)
      r=-8.250e+00;
//--- check
   if(w==14)
      r=-8.469e+00;
//--- check
   if(w==13)
      r=-8.692e+00;
//--- check
   if(w==12)
      r=-8.921e+00;
//--- check
   if(w==11)
      r=-9.162e+00;
//--- check
   if(w==10)
      r=-9.409e+00;
//--- check
   if(w==9)
      r=-9.673e+00;
//--- check
   if(w==8)
      r=-9.951e+00;
//--- check
   if(w==7)
      r=-1.023e+01;
//--- check
   if(w==6)
      r=-1.053e+01;
//--- check
   if(w==5)
      r=-1.087e+01;
//--- check
   if(w==4)
      r=-1.122e+01;
//--- check
   if(w==3)
      r=-1.156e+01;
//--- check
   if(w==2)
      r=-1.207e+01;
//--- check
   if(w==1)
      r=-1.248e+01;
//--- check
   if(w<=0)
      r=-1.317e+01;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 20)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W20(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(2.678619e+01*s)+1.050000e+02);
   if(w>=105)
      r=-6.787e-01;
//--- check
   if(w==104)
      r=-7.078e-01;
//--- check
   if(w==103)
      r=-7.378e-01;
//--- check
   if(w==102)
      r=-7.686e-01;
//--- check
   if(w==101)
      r=-8.004e-01;
//--- check
   if(w==100)
      r=-8.330e-01;
//--- check
   if(w==99)
      r=-8.665e-01;
//--- check
   if(w==98)
      r=-9.010e-01;
//--- check
   if(w==97)
      r=-9.363e-01;
//--- check
   if(w==96)
      r=-9.726e-01;
//--- check
   if(w==95)
      r=-1.010e+00;
//--- check
   if(w==94)
      r=-1.048e+00;
//--- check
   if(w==93)
      r=-1.087e+00;
//--- check
   if(w==92)
      r=-1.128e+00;
//--- check
   if(w==91)
      r=-1.169e+00;
//--- check
   if(w==90)
      r=-1.211e+00;
//--- check
   if(w==89)
      r=-1.254e+00;
//--- check
   if(w==88)
      r=-1.299e+00;
//--- check
   if(w==87)
      r=-1.344e+00;
//--- check
   if(w==86)
      r=-1.390e+00;
//--- check
   if(w==85)
      r=-1.438e+00;
//--- check
   if(w==84)
      r=-1.486e+00;
//--- check
   if(w==83)
      r=-1.536e+00;
//--- check
   if(w==82)
      r=-1.587e+00;
//--- check
   if(w==81)
      r=-1.639e+00;
//--- check
   if(w==80)
      r=-1.692e+00;
//--- check
   if(w==79)
      r=-1.746e+00;
//--- check
   if(w==78)
      r=-1.802e+00;
//--- check
   if(w==77)
      r=-1.859e+00;
//--- check
   if(w==76)
      r=-1.916e+00;
//--- check
   if(w==75)
      r=-1.976e+00;
//--- check
   if(w==74)
      r=-2.036e+00;
//--- check
   if(w==73)
      r=-2.098e+00;
//--- check
   if(w==72)
      r=-2.161e+00;
//--- check
   if(w==71)
      r=-2.225e+00;
//--- check
   if(w==70)
      r=-2.290e+00;
//--- check
   if(w==69)
      r=-2.357e+00;
//--- check
   if(w==68)
      r=-2.426e+00;
//--- check
   if(w==67)
      r=-2.495e+00;
//--- check
   if(w==66)
      r=-2.566e+00;
//--- check
   if(w==65)
      r=-2.639e+00;
//--- check
   if(w==64)
      r=-2.713e+00;
//--- check
   if(w==63)
      r=-2.788e+00;
//--- check
   if(w==62)
      r=-2.865e+00;
//--- check
   if(w==61)
      r=-2.943e+00;
//--- check
   if(w==60)
      r=-3.023e+00;
//--- check
   if(w==59)
      r=-3.104e+00;
//--- check
   if(w==58)
      r=-3.187e+00;
//--- check
   if(w==57)
      r=-3.272e+00;
//--- check
   if(w==56)
      r=-3.358e+00;
//--- check
   if(w==55)
      r=-3.446e+00;
//--- check
   if(w==54)
      r=-3.536e+00;
//--- check
   if(w==53)
      r=-3.627e+00;
//--- check
   if(w==52)
      r=-3.721e+00;
//--- check
   if(w==51)
      r=-3.815e+00;
//--- check
   if(w==50)
      r=-3.912e+00;
//--- check
   if(w==49)
      r=-4.011e+00;
//--- check
   if(w==48)
      r=-4.111e+00;
//--- check
   if(w==47)
      r=-4.214e+00;
//--- check
   if(w==46)
      r=-4.318e+00;
//--- check
   if(w==45)
      r=-4.425e+00;
//--- check
   if(w==44)
      r=-4.534e+00;
//--- check
   if(w==43)
      r=-4.644e+00;
//--- check
   if(w==42)
      r=-4.757e+00;
//--- check
   if(w==41)
      r=-4.872e+00;
//--- check
   if(w==40)
      r=-4.990e+00;
//--- check
   if(w==39)
      r=-5.109e+00;
//--- check
   if(w==38)
      r=-5.232e+00;
//--- check
   if(w==37)
      r=-5.356e+00;
//--- check
   if(w==36)
      r=-5.484e+00;
//--- check
   if(w==35)
      r=-5.614e+00;
//--- check
   if(w==34)
      r=-5.746e+00;
//--- check
   if(w==33)
      r=-5.882e+00;
//--- check
   if(w==32)
      r=-6.020e+00;
//--- check
   if(w==31)
      r=-6.161e+00;
//--- check
   if(w==30)
      r=-6.305e+00;
//--- check
   if(w==29)
      r=-6.453e+00;
//--- check
   if(w==28)
      r=-6.603e+00;
//--- check
   if(w==27)
      r=-6.757e+00;
//--- check
   if(w==26)
      r=-6.915e+00;
//--- check
   if(w==25)
      r=-7.076e+00;
//--- check
   if(w==24)
      r=-7.242e+00;
//--- check
   if(w==23)
      r=-7.411e+00;
//--- check
   if(w==22)
      r=-7.584e+00;
//--- check
   if(w==21)
      r=-7.763e+00;
//--- check
   if(w==20)
      r=-7.947e+00;
//--- check
   if(w==19)
      r=-8.136e+00;
//--- check
   if(w==18)
      r=-8.330e+00;
//--- check
   if(w==17)
      r=-8.530e+00;
//--- check
   if(w==16)
      r=-8.733e+00;
//--- check
   if(w==15)
      r=-8.943e+00;
//--- check
   if(w==14)
      r=-9.162e+00;
//--- check
   if(w==13)
      r=-9.386e+00;
//--- check
   if(w==12)
      r=-9.614e+00;
//--- check
   if(w==11)
      r=-9.856e+00;
//--- check
   if(w==10)
      r=-1.010e+01;
//--- check
   if(w==9)
      r=-1.037e+01;
//--- check
   if(w==8)
      r=-1.064e+01;
//--- check
   if(w==7)
      r=-1.092e+01;
//--- check
   if(w==6)
      r=-1.122e+01;
//--- check
   if(w==5)
      r=-1.156e+01;
//--- check
   if(w==4)
      r=-1.192e+01;
//--- check
   if(w==3)
      r=-1.225e+01;
//--- check
   if(w==2)
      r=-1.276e+01;
//--- check
   if(w==1)
      r=-1.317e+01;
//--- check
   if(w<=0)
      r=-1.386e+01;
//---
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 21)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W21(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(2.877064e+01*s)+1.155000e+02);
   if(w>=115)
      r=-6.931e-01;
//--- check
   if(w==114)
      r=-7.207e-01;
//--- check
   if(w==113)
      r=-7.489e-01;
//--- check
   if(w==112)
      r=-7.779e-01;
//--- check
   if(w==111)
      r=-8.077e-01;
//--- check
   if(w==110)
      r=-8.383e-01;
//--- check
   if(w==109)
      r=-8.697e-01;
//--- check
   if(w==108)
      r=-9.018e-01;
//--- check
   if(w==107)
      r=-9.348e-01;
//--- check
   if(w==106)
      r=-9.685e-01;
//--- check
   if(w==105)
      r=-1.003e+00;
//--- check
   if(w==104)
      r=-1.039e+00;
//--- check
   if(w==103)
      r=-1.075e+00;
//--- check
   if(w==102)
      r=-1.112e+00;
//--- check
   if(w==101)
      r=-1.150e+00;
//--- check
   if(w==100)
      r=-1.189e+00;
//--- check
   if(w==99)
      r=-1.229e+00;
//--- check
   if(w==98)
      r=-1.269e+00;
//--- check
   if(w==97)
      r=-1.311e+00;
//--- check
   if(w==96)
      r=-1.353e+00;
//--- check
   if(w==95)
      r=-1.397e+00;
//--- check
   if(w==94)
      r=-1.441e+00;
//--- check
   if(w==93)
      r=-1.486e+00;
//--- check
   if(w==92)
      r=-1.533e+00;
//--- check
   if(w==91)
      r=-1.580e+00;
//--- check
   if(w==90)
      r=-1.628e+00;
//--- check
   if(w==89)
      r=-1.677e+00;
//--- check
   if(w==88)
      r=-1.728e+00;
//--- check
   if(w==87)
      r=-1.779e+00;
//--- check
   if(w==86)
      r=-1.831e+00;
//--- check
   if(w==85)
      r=-1.884e+00;
//--- check
   if(w==84)
      r=-1.939e+00;
//--- check
   if(w==83)
      r=-1.994e+00;
//--- check
   if(w==82)
      r=-2.051e+00;
//--- check
   if(w==81)
      r=-2.108e+00;
//--- check
   if(w==80)
      r=-2.167e+00;
//--- check
   if(w==79)
      r=-2.227e+00;
//--- check
   if(w==78)
      r=-2.288e+00;
//--- check
   if(w==77)
      r=-2.350e+00;
//--- check
   if(w==76)
      r=-2.414e+00;
//--- check
   if(w==75)
      r=-2.478e+00;
//--- check
   if(w==74)
      r=-2.544e+00;
//--- check
   if(w==73)
      r=-2.611e+00;
//--- check
   if(w==72)
      r=-2.679e+00;
//--- check
   if(w==71)
      r=-2.748e+00;
//--- check
   if(w==70)
      r=-2.819e+00;
//--- check
   if(w==69)
      r=-2.891e+00;
//--- check
   if(w==68)
      r=-2.964e+00;
//--- check
   if(w==67)
      r=-3.039e+00;
//--- check
   if(w==66)
      r=-3.115e+00;
//--- check
   if(w==65)
      r=-3.192e+00;
//--- check
   if(w==64)
      r=-3.270e+00;
//--- check
   if(w==63)
      r=-3.350e+00;
//--- check
   if(w==62)
      r=-3.432e+00;
//--- check
   if(w==61)
      r=-3.515e+00;
//--- check
   if(w==60)
      r=-3.599e+00;
//--- check
   if(w==59)
      r=-3.685e+00;
//--- check
   if(w==58)
      r=-3.772e+00;
//--- check
   if(w==57)
      r=-3.861e+00;
//--- check
   if(w==56)
      r=-3.952e+00;
//--- check
   if(w==55)
      r=-4.044e+00;
//--- check
   if(w==54)
      r=-4.138e+00;
//--- check
   if(w==53)
      r=-4.233e+00;
//--- check
   if(w==52)
      r=-4.330e+00;
//--- check
   if(w==51)
      r=-4.429e+00;
//--- check
   if(w==50)
      r=-4.530e+00;
//--- check
   if(w==49)
      r=-4.632e+00;
//--- check
   if(w==48)
      r=-4.736e+00;
//--- check
   if(w==47)
      r=-4.842e+00;
//--- check
   if(w==46)
      r=-4.950e+00;
//--- check
   if(w==45)
      r=-5.060e+00;
//--- check
   if(w==44)
      r=-5.172e+00;
//--- check
   if(w==43)
      r=-5.286e+00;
//--- check
   if(w==42)
      r=-5.402e+00;
//--- check
   if(w==41)
      r=-5.520e+00;
//--- check
   if(w==40)
      r=-5.641e+00;
//--- check
   if(w==39)
      r=-5.763e+00;
//--- check
   if(w==38)
      r=-5.889e+00;
//--- check
   if(w==37)
      r=-6.016e+00;
//--- check
   if(w==36)
      r=-6.146e+00;
//--- check
   if(w==35)
      r=-6.278e+00;
//--- check
   if(w==34)
      r=-6.413e+00;
//--- check
   if(w==33)
      r=-6.551e+00;
//--- check
   if(w==32)
      r=-6.692e+00;
//--- check
   if(w==31)
      r=-6.835e+00;
//--- check
   if(w==30)
      r=-6.981e+00;
//--- check
   if(w==29)
      r=-7.131e+00;
//--- check
   if(w==28)
      r=-7.283e+00;
//--- check
   if(w==27)
      r=-7.439e+00;
//--- check
   if(w==26)
      r=-7.599e+00;
//--- check
   if(w==25)
      r=-7.762e+00;
//--- check
   if(w==24)
      r=-7.928e+00;
//--- check
   if(w==23)
      r=-8.099e+00;
//--- check
   if(w==22)
      r=-8.274e+00;
//--- check
   if(w==21)
      r=-8.454e+00;
//--- check
   if(w==20)
      r=-8.640e+00;
//--- check
   if(w==19)
      r=-8.829e+00;
//--- check
   if(w==18)
      r=-9.023e+00;
//--- check
   if(w==17)
      r=-9.223e+00;
//--- check
   if(w==16)
      r=-9.426e+00;
//--- check
   if(w==15)
      r=-9.636e+00;
//--- check
   if(w==14)
      r=-9.856e+00;
//--- check
   if(w==13)
      r=-1.008e+01;
//--- check
   if(w==12)
      r=-1.031e+01;
//--- check
   if(w==11)
      r=-1.055e+01;
//--- check
   if(w==10)
      r=-1.079e+01;
//--- check
   if(w==9)
      r=-1.106e+01;
//--- check
   if(w==8)
      r=-1.134e+01;
//--- check
   if(w==7)
      r=-1.161e+01;
//--- check
   if(w==6)
      r=-1.192e+01;
//--- check
   if(w==5)
      r=-1.225e+01;
//--- check
   if(w==4)
      r=-1.261e+01;
//--- check
   if(w==3)
      r=-1.295e+01;
//--- check
   if(w==2)
      r=-1.346e+01;
//--- check
   if(w==1)
      r=-1.386e+01;
//--- check
   if(w<=0)
      r=-1.456e+01;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 22)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W22(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(3.080179e+01*s)+1.265000e+02);
   if(w>=126)
      r=-6.931e-01;
//--- check
   if(w==125)
      r=-7.189e-01;
//--- check
   if(w==124)
      r=-7.452e-01;
//--- check
   if(w==123)
      r=-7.722e-01;
//--- check
   if(w==122)
      r=-7.999e-01;
//--- check
   if(w==121)
      r=-8.283e-01;
//--- check
   if(w==120)
      r=-8.573e-01;
//--- check
   if(w==119)
      r=-8.871e-01;
//--- check
   if(w==118)
      r=-9.175e-01;
//--- check
   if(w==117)
      r=-9.486e-01;
//--- check
   if(w==116)
      r=-9.805e-01;
//--- check
   if(w==115)
      r=-1.013e+00;
//--- check
   if(w==114)
      r=-1.046e+00;
//--- check
   if(w==113)
      r=-1.080e+00;
//--- check
   if(w==112)
      r=-1.115e+00;
//--- check
   if(w==111)
      r=-1.151e+00;
//--- check
   if(w==110)
      r=-1.187e+00;
//--- check
   if(w==109)
      r=-1.224e+00;
//--- check
   if(w==108)
      r=-1.262e+00;
//--- check
   if(w==107)
      r=-1.301e+00;
//--- check
   if(w==106)
      r=-1.340e+00;
//--- check
   if(w==105)
      r=-1.381e+00;
//--- check
   if(w==104)
      r=-1.422e+00;
//--- check
   if(w==103)
      r=-1.464e+00;
//--- check
   if(w==102)
      r=-1.506e+00;
//--- check
   if(w==101)
      r=-1.550e+00;
//--- check
   if(w==100)
      r=-1.594e+00;
//--- check
   if(w==99)
      r=-1.640e+00;
//--- check
   if(w==98)
      r=-1.686e+00;
//--- check
   if(w==97)
      r=-1.733e+00;
//--- check
   if(w==96)
      r=-1.781e+00;
//--- check
   if(w==95)
      r=-1.830e+00;
//--- check
   if(w==94)
      r=-1.880e+00;
//--- check
   if(w==93)
      r=-1.930e+00;
//--- check
   if(w==92)
      r=-1.982e+00;
//--- check
   if(w==91)
      r=-2.034e+00;
//--- check
   if(w==90)
      r=-2.088e+00;
//--- check
   if(w==89)
      r=-2.142e+00;
//--- check
   if(w==88)
      r=-2.198e+00;
//--- check
   if(w==87)
      r=-2.254e+00;
//--- check
   if(w==86)
      r=-2.312e+00;
//--- check
   if(w==85)
      r=-2.370e+00;
//--- check
   if(w==84)
      r=-2.429e+00;
//--- check
   if(w==83)
      r=-2.490e+00;
//--- check
   if(w==82)
      r=-2.551e+00;
//--- check
   if(w==81)
      r=-2.614e+00;
//--- check
   if(w==80)
      r=-2.677e+00;
//--- check
   if(w==79)
      r=-2.742e+00;
//--- check
   if(w==78)
      r=-2.808e+00;
//--- check
   if(w==77)
      r=-2.875e+00;
//--- check
   if(w==76)
      r=-2.943e+00;
//--- check
   if(w==75)
      r=-3.012e+00;
//--- check
   if(w==74)
      r=-3.082e+00;
//--- check
   if(w==73)
      r=-3.153e+00;
//--- check
   if(w==72)
      r=-3.226e+00;
//--- check
   if(w==71)
      r=-3.300e+00;
//--- check
   if(w==70)
      r=-3.375e+00;
//--- check
   if(w==69)
      r=-3.451e+00;
//--- check
   if(w==68)
      r=-3.529e+00;
//--- check
   if(w==67)
      r=-3.607e+00;
//--- check
   if(w==66)
      r=-3.687e+00;
//--- check
   if(w==65)
      r=-3.769e+00;
//--- check
   if(w==64)
      r=-3.851e+00;
//--- check
   if(w==63)
      r=-3.935e+00;
//--- check
   if(w==62)
      r=-4.021e+00;
//--- check
   if(w==61)
      r=-4.108e+00;
//--- check
   if(w==60)
      r=-4.196e+00;
//--- check
   if(w==59)
      r=-4.285e+00;
//--- check
   if(w==58)
      r=-4.376e+00;
//--- check
   if(w==57)
      r=-4.469e+00;
//--- check
   if(w==56)
      r=-4.563e+00;
//--- check
   if(w==55)
      r=-4.659e+00;
//--- check
   if(w==54)
      r=-4.756e+00;
//--- check
   if(w==53)
      r=-4.855e+00;
//--- check
   if(w==52)
      r=-4.955e+00;
//--- check
   if(w==51)
      r=-5.057e+00;
//--- check
   if(w==50)
      r=-5.161e+00;
//--- check
   if(w==49)
      r=-5.266e+00;
//--- check
   if(w==48)
      r=-5.374e+00;
//--- check
   if(w==47)
      r=-5.483e+00;
//--- check
   if(w==46)
      r=-5.594e+00;
//--- check
   if(w==45)
      r=-5.706e+00;
//--- check
   if(w==44)
      r=-5.821e+00;
//--- check
   if(w==43)
      r=-5.938e+00;
//--- check
   if(w==42)
      r=-6.057e+00;
//--- check
   if(w==41)
      r=-6.177e+00;
//--- check
   if(w==40)
      r=-6.300e+00;
//--- check
   if(w==39)
      r=-6.426e+00;
//--- check
   if(w==38)
      r=-6.553e+00;
//--- check
   if(w==37)
      r=-6.683e+00;
//--- check
   if(w==36)
      r=-6.815e+00;
//--- check
   if(w==35)
      r=-6.949e+00;
//--- check
   if(w==34)
      r=-7.086e+00;
//--- check
   if(w==33)
      r=-7.226e+00;
//--- check
   if(w==32)
      r=-7.368e+00;
//--- check
   if(w==31)
      r=-7.513e+00;
//--- check
   if(w==30)
      r=-7.661e+00;
//--- check
   if(w==29)
      r=-7.813e+00;
//--- check
   if(w==28)
      r=-7.966e+00;
//--- check
   if(w==27)
      r=-8.124e+00;
//--- check
   if(w==26)
      r=-8.285e+00;
//--- check
   if(w==25)
      r=-8.449e+00;
//--- check
   if(w==24)
      r=-8.617e+00;
//--- check
   if(w==23)
      r=-8.789e+00;
//--- check
   if(w==22)
      r=-8.965e+00;
//--- check
   if(w==21)
      r=-9.147e+00;
//--- check
   if(w==20)
      r=-9.333e+00;
//--- check
   if(w==19)
      r=-9.522e+00;
//--- check
   if(w==18)
      r=-9.716e+00;
//--- check
   if(w==17)
      r=-9.917e+00;
//--- check
   if(w==16)
      r=-1.012e+01;
//--- check
   if(w==15)
      r=-1.033e+01;
//--- check
   if(w==14)
      r=-1.055e+01;
//--- check
   if(w==13)
      r=-1.077e+01;
//--- check
   if(w==12)
      r=-1.100e+01;
//--- check
   if(w==11)
      r=-1.124e+01;
//--- check
   if(w==10)
      r=-1.149e+01;
//--- check
   if(w==9)
      r=-1.175e+01;
//--- check
   if(w==8)
      r=-1.203e+01;
//--- check
   if(w==7)
      r=-1.230e+01;
//--- check
   if(w==6)
      r=-1.261e+01;
//--- check
   if(w==5)
      r=-1.295e+01;
//--- check
   if(w==4)
      r=-1.330e+01;
//--- check
   if(w==3)
      r=-1.364e+01;
//--- check
   if(w==2)
      r=-1.415e+01;
//--- check
   if(w==1)
      r=-1.456e+01;
//--- check
   if(w<=0)
      r=-1.525e+01;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 23)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W23(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(3.287856e+01*s)+1.380000e+02);
   if(w>=138)
      r=-6.813e-01;
//--- check
   if(w==137)
      r=-7.051e-01;
//--- check
   if(w==136)
      r=-7.295e-01;
//--- check
   if(w==135)
      r=-7.544e-01;
//--- check
   if(w==134)
      r=-7.800e-01;
//--- check
   if(w==133)
      r=-8.061e-01;
//--- check
   if(w==132)
      r=-8.328e-01;
//--- check
   if(w==131)
      r=-8.601e-01;
//--- check
   if(w==130)
      r=-8.880e-01;
//--- check
   if(w==129)
      r=-9.166e-01;
//--- check
   if(w==128)
      r=-9.457e-01;
//--- check
   if(w==127)
      r=-9.755e-01;
//--- check
   if(w==126)
      r=-1.006e+00;
//--- check
   if(w==125)
      r=-1.037e+00;
//--- check
   if(w==124)
      r=-1.069e+00;
//--- check
   if(w==123)
      r=-1.101e+00;
//--- check
   if(w==122)
      r=-1.134e+00;
//--- check
   if(w==121)
      r=-1.168e+00;
//--- check
   if(w==120)
      r=-1.202e+00;
//--- check
   if(w==119)
      r=-1.237e+00;
//--- check
   if(w==118)
      r=-1.273e+00;
//--- check
   if(w==117)
      r=-1.309e+00;
//--- check
   if(w==116)
      r=-1.347e+00;
//--- check
   if(w==115)
      r=-1.384e+00;
//--- check
   if(w==114)
      r=-1.423e+00;
//--- check
   if(w==113)
      r=-1.462e+00;
//--- check
   if(w==112)
      r=-1.502e+00;
//--- check
   if(w==111)
      r=-1.543e+00;
//--- check
   if(w==110)
      r=-1.585e+00;
//--- check
   if(w==109)
      r=-1.627e+00;
//--- check
   if(w==108)
      r=-1.670e+00;
//--- check
   if(w==107)
      r=-1.714e+00;
//--- check
   if(w==106)
      r=-1.758e+00;
//--- check
   if(w==105)
      r=-1.804e+00;
//--- check
   if(w==104)
      r=-1.850e+00;
//--- check
   if(w==103)
      r=-1.897e+00;
//--- check
   if(w==102)
      r=-1.944e+00;
//--- check
   if(w==101)
      r=-1.993e+00;
//--- check
   if(w==100)
      r=-2.042e+00;
//--- check
   if(w==99)
      r=-2.093e+00;
//--- check
   if(w==98)
      r=-2.144e+00;
//--- check
   if(w==97)
      r=-2.195e+00;
//--- check
   if(w==96)
      r=-2.248e+00;
//--- check
   if(w==95)
      r=-2.302e+00;
//--- check
   if(w==94)
      r=-2.356e+00;
//--- check
   if(w==93)
      r=-2.412e+00;
//--- check
   if(w==92)
      r=-2.468e+00;
//--- check
   if(w==91)
      r=-2.525e+00;
//--- check
   if(w==90)
      r=-2.583e+00;
//--- check
   if(w==89)
      r=-2.642e+00;
//--- check
   if(w==88)
      r=-2.702e+00;
//--- check
   if(w==87)
      r=-2.763e+00;
//--- check
   if(w==86)
      r=-2.825e+00;
//--- check
   if(w==85)
      r=-2.888e+00;
//--- check
   if(w==84)
      r=-2.951e+00;
//--- check
   if(w==83)
      r=-3.016e+00;
//--- check
   if(w==82)
      r=-3.082e+00;
//--- check
   if(w==81)
      r=-3.149e+00;
//--- check
   if(w==80)
      r=-3.216e+00;
//--- check
   if(w==79)
      r=-3.285e+00;
//--- check
   if(w==78)
      r=-3.355e+00;
//--- check
   if(w==77)
      r=-3.426e+00;
//--- check
   if(w==76)
      r=-3.498e+00;
//--- check
   if(w==75)
      r=-3.571e+00;
//--- check
   if(w==74)
      r=-3.645e+00;
//--- check
   if(w==73)
      r=-3.721e+00;
//--- check
   if(w==72)
      r=-3.797e+00;
//--- check
   if(w==71)
      r=-3.875e+00;
//--- check
   if(w==70)
      r=-3.953e+00;
//--- check
   if(w==69)
      r=-4.033e+00;
//--- check
   if(w==68)
      r=-4.114e+00;
//--- check
   if(w==67)
      r=-4.197e+00;
//--- check
   if(w==66)
      r=-4.280e+00;
//--- check
   if(w==65)
      r=-4.365e+00;
//--- check
   if(w==64)
      r=-4.451e+00;
//--- check
   if(w==63)
      r=-4.539e+00;
//--- check
   if(w==62)
      r=-4.628e+00;
//--- check
   if(w==61)
      r=-4.718e+00;
//--- check
   if(w==60)
      r=-4.809e+00;
//--- check
   if(w==59)
      r=-4.902e+00;
//--- check
   if(w==58)
      r=-4.996e+00;
//--- check
   if(w==57)
      r=-5.092e+00;
//--- check
   if(w==56)
      r=-5.189e+00;
//--- check
   if(w==55)
      r=-5.287e+00;
//--- check
   if(w==54)
      r=-5.388e+00;
//--- check
   if(w==53)
      r=-5.489e+00;
//--- check
   if(w==52)
      r=-5.592e+00;
//--- check
   if(w==51)
      r=-5.697e+00;
//--- check
   if(w==50)
      r=-5.804e+00;
//--- check
   if(w==49)
      r=-5.912e+00;
//--- check
   if(w==48)
      r=-6.022e+00;
//--- check
   if(w==47)
      r=-6.133e+00;
//--- check
   if(w==46)
      r=-6.247e+00;
//--- check
   if(w==45)
      r=-6.362e+00;
//--- check
   if(w==44)
      r=-6.479e+00;
//--- check
   if(w==43)
      r=-6.598e+00;
//--- check
   if(w==42)
      r=-6.719e+00;
//--- check
   if(w==41)
      r=-6.842e+00;
//--- check
   if(w==40)
      r=-6.967e+00;
//--- check
   if(w==39)
      r=-7.094e+00;
//--- check
   if(w==38)
      r=-7.224e+00;
//--- check
   if(w==37)
      r=-7.355e+00;
//--- check
   if(w==36)
      r=-7.489e+00;
//--- check
   if(w==35)
      r=-7.625e+00;
//--- check
   if(w==34)
      r=-7.764e+00;
//--- check
   if(w==33)
      r=-7.905e+00;
//--- check
   if(w==32)
      r=-8.049e+00;
//--- check
   if(w==31)
      r=-8.196e+00;
//--- check
   if(w==30)
      r=-8.345e+00;
//--- check
   if(w==29)
      r=-8.498e+00;
//--- check
   if(w==28)
      r=-8.653e+00;
//--- check
   if(w==27)
      r=-8.811e+00;
//--- check
   if(w==26)
      r=-8.974e+00;
//--- check
   if(w==25)
      r=-9.139e+00;
//--- check
   if(w==24)
      r=-9.308e+00;
//--- check
   if(w==23)
      r=-9.481e+00;
//--- check
   if(w==22)
      r=-9.658e+00;
//--- check
   if(w==21)
      r=-9.840e+00;
//--- check
   if(w==20)
      r=-1.003e+01;
//--- check
   if(w==19)
      r=-1.022e+01;
//--- check
   if(w==18)
      r=-1.041e+01;
//--- check
   if(w==17)
      r=-1.061e+01;
//--- check
   if(w==16)
      r=-1.081e+01;
//--- check
   if(w==15)
      r=-1.102e+01;
//--- check
   if(w==14)
      r=-1.124e+01;
//--- check
   if(w==13)
      r=-1.147e+01;
//--- check
   if(w==12)
      r=-1.169e+01;
//--- check
   if(w==11)
      r=-1.194e+01;
//--- check
   if(w==10)
      r=-1.218e+01;
//--- check
   if(w==9)
      r=-1.245e+01;
//--- check
   if(w==8)
      r=-1.272e+01;
//--- check
   if(w==7)
      r=-1.300e+01;
//--- check
   if(w==6)
      r=-1.330e+01;
//--- check
   if(w==5)
      r=-1.364e+01;
//--- check
   if(w==4)
      r=-1.400e+01;
//--- check
   if(w==3)
      r=-1.433e+01;
//--- check
   if(w==2)
      r=-1.484e+01;
//--- check
   if(w==1)
      r=-1.525e+01;
//--- check
   if(w<=0)
      r=-1.594e+01;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 24)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W24(const double s)
  {
//--- create variables
   int    w=0;
   double r=0;
//--- check
   w=(int)MathRound(-(3.500000e+01*s)+1.500000e+02);
   if(w>=150)
      r=-6.820e-01;
//--- check
   if(w==149)
      r=-7.044e-01;
//--- check
   if(w==148)
      r=-7.273e-01;
//--- check
   if(w==147)
      r=-7.507e-01;
//--- check
   if(w==146)
      r=-7.746e-01;
//--- check
   if(w==145)
      r=-7.990e-01;
//--- check
   if(w==144)
      r=-8.239e-01;
//--- check
   if(w==143)
      r=-8.494e-01;
//--- check
   if(w==142)
      r=-8.754e-01;
//--- check
   if(w==141)
      r=-9.020e-01;
//--- check
   if(w==140)
      r=-9.291e-01;
//--- check
   if(w==139)
      r=-9.567e-01;
//--- check
   if(w==138)
      r=-9.849e-01;
//--- check
   if(w==137)
      r=-1.014e+00;
//--- check
   if(w==136)
      r=-1.043e+00;
//--- check
   if(w==135)
      r=-1.073e+00;
//--- check
   if(w==134)
      r=-1.103e+00;
//--- check
   if(w==133)
      r=-1.135e+00;
//--- check
   if(w==132)
      r=-1.166e+00;
//--- check
   if(w==131)
      r=-1.198e+00;
//--- check
   if(w==130)
      r=-1.231e+00;
//--- check
   if(w==129)
      r=-1.265e+00;
//--- check
   if(w==128)
      r=-1.299e+00;
//--- check
   if(w==127)
      r=-1.334e+00;
//--- check
   if(w==126)
      r=-1.369e+00;
//--- check
   if(w==125)
      r=-1.405e+00;
//--- check
   if(w==124)
      r=-1.441e+00;
//--- check
   if(w==123)
      r=-1.479e+00;
//--- check
   if(w==122)
      r=-1.517e+00;
//--- check
   if(w==121)
      r=-1.555e+00;
//--- check
   if(w==120)
      r=-1.594e+00;
//--- check
   if(w==119)
      r=-1.634e+00;
//--- check
   if(w==118)
      r=-1.675e+00;
//--- check
   if(w==117)
      r=-1.716e+00;
//--- check
   if(w==116)
      r=-1.758e+00;
//--- check
   if(w==115)
      r=-1.800e+00;
//--- check
   if(w==114)
      r=-1.844e+00;
//--- check
   if(w==113)
      r=-1.888e+00;
//--- check
   if(w==112)
      r=-1.932e+00;
//--- check
   if(w==111)
      r=-1.978e+00;
//--- check
   if(w==110)
      r=-2.024e+00;
//--- check
   if(w==109)
      r=-2.070e+00;
//--- check
   if(w==108)
      r=-2.118e+00;
//--- check
   if(w==107)
      r=-2.166e+00;
//--- check
   if(w==106)
      r=-2.215e+00;
//--- check
   if(w==105)
      r=-2.265e+00;
//--- check
   if(w==104)
      r=-2.316e+00;
//--- check
   if(w==103)
      r=-2.367e+00;
//--- check
   if(w==102)
      r=-2.419e+00;
//--- check
   if(w==101)
      r=-2.472e+00;
//--- check
   if(w==100)
      r=-2.526e+00;
//--- check
   if(w==99)
      r=-2.580e+00;
//--- check
   if(w==98)
      r=-2.636e+00;
//--- check
   if(w==97)
      r=-2.692e+00;
//--- check
   if(w==96)
      r=-2.749e+00;
//--- check
   if(w==95)
      r=-2.806e+00;
//--- check
   if(w==94)
      r=-2.865e+00;
//--- check
   if(w==93)
      r=-2.925e+00;
//--- check
   if(w==92)
      r=-2.985e+00;
//--- check
   if(w==91)
      r=-3.046e+00;
//--- check
   if(w==90)
      r=-3.108e+00;
//--- check
   if(w==89)
      r=-3.171e+00;
//--- check
   if(w==88)
      r=-3.235e+00;
//--- check
   if(w==87)
      r=-3.300e+00;
//--- check
   if(w==86)
      r=-3.365e+00;
//--- check
   if(w==85)
      r=-3.432e+00;
//--- check
   if(w==84)
      r=-3.499e+00;
//--- check
   if(w==83)
      r=-3.568e+00;
//--- check
   if(w==82)
      r=-3.637e+00;
//--- check
   if(w==81)
      r=-3.708e+00;
//--- check
   if(w==80)
      r=-3.779e+00;
//--- check
   if(w==79)
      r=-3.852e+00;
//--- check
   if(w==78)
      r=-3.925e+00;
//--- check
   if(w==77)
      r=-4.000e+00;
//--- check
   if(w==76)
      r=-4.075e+00;
//--- check
   if(w==75)
      r=-4.151e+00;
//--- check
   if(w==74)
      r=-4.229e+00;
//--- check
   if(w==73)
      r=-4.308e+00;
//--- check
   if(w==72)
      r=-4.387e+00;
//--- check
   if(w==71)
      r=-4.468e+00;
//--- check
   if(w==70)
      r=-4.550e+00;
//--- check
   if(w==69)
      r=-4.633e+00;
//--- check
   if(w==68)
      r=-4.718e+00;
//--- check
   if(w==67)
      r=-4.803e+00;
//--- check
   if(w==66)
      r=-4.890e+00;
//--- check
   if(w==65)
      r=-4.978e+00;
//--- check
   if(w==64)
      r=-5.067e+00;
//--- check
   if(w==63)
      r=-5.157e+00;
//--- check
   if(w==62)
      r=-5.249e+00;
//--- check
   if(w==61)
      r=-5.342e+00;
//--- check
   if(w==60)
      r=-5.436e+00;
//--- check
   if(w==59)
      r=-5.531e+00;
//--- check
   if(w==58)
      r=-5.628e+00;
//--- check
   if(w==57)
      r=-5.727e+00;
//--- check
   if(w==56)
      r=-5.826e+00;
//--- check
   if(w==55)
      r=-5.927e+00;
//--- check
   if(w==54)
      r=-6.030e+00;
//--- check
   if(w==53)
      r=-6.134e+00;
//--- check
   if(w==52)
      r=-6.240e+00;
//--- check
   if(w==51)
      r=-6.347e+00;
//--- check
   if(w==50)
      r=-6.456e+00;
//--- check
   if(w==49)
      r=-6.566e+00;
//--- check
   if(w==48)
      r=-6.678e+00;
//--- check
   if(w==47)
      r=-6.792e+00;
//--- check
   if(w==46)
      r=-6.907e+00;
//--- check
   if(w==45)
      r=-7.025e+00;
//--- check
   if(w==44)
      r=-7.144e+00;
//--- check
   if(w==43)
      r=-7.265e+00;
//--- check
   if(w==42)
      r=-7.387e+00;
//--- check
   if(w==41)
      r=-7.512e+00;
//--- check
   if(w==40)
      r=-7.639e+00;
//--- check
   if(w==39)
      r=-7.768e+00;
//--- check
   if(w==38)
      r=-7.899e+00;
//--- check
   if(w==37)
      r=-8.032e+00;
//--- check
   if(w==36)
      r=-8.167e+00;
//--- check
   if(w==35)
      r=-8.305e+00;
//--- check
   if(w==34)
      r=-8.445e+00;
//--- check
   if(w==33)
      r=-8.588e+00;
//--- check
   if(w==32)
      r=-8.733e+00;
//--- check
   if(w==31)
      r=-8.881e+00;
//--- check
   if(w==30)
      r=-9.031e+00;
//--- check
   if(w==29)
      r=-9.185e+00;
//--- check
   if(w==28)
      r=-9.341e+00;
//--- check
   if(w==27)
      r=-9.501e+00;
//--- check
   if(w==26)
      r=-9.664e+00;
//--- check
   if(w==25)
      r=-9.830e+00;
//--- check
   if(w==24)
      r=-1.000e+01;
//--- check
   if(w==23)
      r=-1.017e+01;
//--- check
   if(w==22)
      r=-1.035e+01;
//--- check
   if(w==21)
      r=-1.053e+01;
//--- check
   if(w==20)
      r=-1.072e+01;
//--- check
   if(w==19)
      r=-1.091e+01;
//--- check
   if(w==18)
      r=-1.110e+01;
//--- check
   if(w==17)
      r=-1.130e+01;
//--- check
   if(w==16)
      r=-1.151e+01;
//--- check
   if(w==15)
      r=-1.172e+01;
//--- check
   if(w==14)
      r=-1.194e+01;
//--- check
   if(w==13)
      r=-1.216e+01;
//--- check
   if(w==12)
      r=-1.239e+01;
//--- check
   if(w==11)
      r=-1.263e+01;
//--- check
   if(w==10)
      r=-1.287e+01;
//--- check
   if(w==9)
      r=-1.314e+01;
//--- check
   if(w==8)
      r=-1.342e+01;
//--- check
   if(w==7)
      r=-1.369e+01;
//--- check
   if(w==6)
      r=-1.400e+01;
//--- check
   if(w==5)
      r=-1.433e+01;
//--- check
   if(w==4)
      r=-1.469e+01;
//--- check
   if(w==3)
      r=-1.503e+01;
//--- check
   if(w==2)
      r=-1.554e+01;
//--- check
   if(w==1)
      r=-1.594e+01;
//--- check
   if(w<=0)
      r=-1.664e+01;
//--- return result
   return(r);
  }
//+------------------------------------------------------------------+
//| Tail(S, 25)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W25(const double s)
  {
//--- create variables
   double result=0;
   double x=0;
   double tj=0;
   double tj1=0;
//--- change values
   x=MathMin(2*(s-0.000000e+00)/4.000000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   WCheb(x,-5.150509e+00,tj,tj1,result);
   WCheb(x,-5.695528e+00,tj,tj1,result);
   WCheb(x,-1.437637e+00,tj,tj1,result);
   WCheb(x,-2.611906e-01,tj,tj1,result);
   WCheb(x,-7.625722e-02,tj,tj1,result);
   WCheb(x,-2.579892e-02,tj,tj1,result);
   WCheb(x,-1.086876e-02,tj,tj1,result);
   WCheb(x,-2.906543e-03,tj,tj1,result);
   WCheb(x,-2.354881e-03,tj,tj1,result);
   WCheb(x,1.007195e-04,tj,tj1,result);
   WCheb(x,-8.437327e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 26)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W26(const double s)
  {
//--- create variables
   double result=0;
   double x=0;
   double tj=0;
   double tj1=0;
//--- change values
   x=MathMin(2*(s-0.000000e+00)/4.000000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   WCheb(x,-5.117622e+00,tj,tj1,result);
   WCheb(x,-5.635159e+00,tj,tj1,result);
   WCheb(x,-1.395167e+00,tj,tj1,result);
   WCheb(x,-2.382823e-01,tj,tj1,result);
   WCheb(x,-6.531987e-02,tj,tj1,result);
   WCheb(x,-2.060112e-02,tj,tj1,result);
   WCheb(x,-8.203697e-03,tj,tj1,result);
   WCheb(x,-1.516523e-03,tj,tj1,result);
   WCheb(x,-1.431364e-03,tj,tj1,result);
   WCheb(x,6.384553e-04,tj,tj1,result);
   WCheb(x,-3.238369e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 27)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W27(const double s)
  {
//--- create variables
   double result=0;
   double x=0;
   double tj=0;
   double tj1=0;
//--- change values
   x=MathMin(2*(s-0.000000e+00)/4.000000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   WCheb(x,-5.089731e+00,tj,tj1,result);
   WCheb(x,-5.584248e+00,tj,tj1,result);
   WCheb(x,-1.359966e+00,tj,tj1,result);
   WCheb(x,-2.203696e-01,tj,tj1,result);
   WCheb(x,-5.753344e-02,tj,tj1,result);
   WCheb(x,-1.761891e-02,tj,tj1,result);
   WCheb(x,-7.096897e-03,tj,tj1,result);
   WCheb(x,-1.419108e-03,tj,tj1,result);
   WCheb(x,-1.581214e-03,tj,tj1,result);
   WCheb(x,3.033766e-04,tj,tj1,result);
   WCheb(x,-5.901441e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 28)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W28(const double s)
  {
//--- create variables
   double result=0;
   double x=0;
   double tj=0;
   double tj1=0;
//--- change values
   x=MathMin(2*(s-0.000000e+00)/4.000000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   WCheb(x,-5.065046e+00,tj,tj1,result);
   WCheb(x,-5.539163e+00,tj,tj1,result);
   WCheb(x,-1.328939e+00,tj,tj1,result);
   WCheb(x,-2.046376e-01,tj,tj1,result);
   WCheb(x,-5.061515e-02,tj,tj1,result);
   WCheb(x,-1.469271e-02,tj,tj1,result);
   WCheb(x,-5.711578e-03,tj,tj1,result);
   WCheb(x,-8.389153e-04,tj,tj1,result);
   WCheb(x,-1.250575e-03,tj,tj1,result);
   WCheb(x,4.047245e-04,tj,tj1,result);
   WCheb(x,-5.128555e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 29)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W29(const double s)
  {
//--- create variables
   double result=0;
   double x=0;
   double tj=0;
   double tj1=0;
//--- change values
   x=MathMin(2*(s-0.000000e+00)/4.000000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   WCheb(x,-5.043413e+00,tj,tj1,result);
   WCheb(x,-5.499756e+00,tj,tj1,result);
   WCheb(x,-1.302137e+00,tj,tj1,result);
   WCheb(x,-1.915129e-01,tj,tj1,result);
   WCheb(x,-4.516329e-02,tj,tj1,result);
   WCheb(x,-1.260064e-02,tj,tj1,result);
   WCheb(x,-4.817269e-03,tj,tj1,result);
   WCheb(x,-5.478130e-04,tj,tj1,result);
   WCheb(x,-1.111668e-03,tj,tj1,result);
   WCheb(x,4.093451e-04,tj,tj1,result);
   WCheb(x,-5.135860e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 30)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W30(const double s)
  {
//--- create variables
   double result=0;
   double x=0;
   double tj=0;
   double tj1=0;
//--- change values
   x=MathMin(2*(s-0.000000e+00)/4.000000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   WCheb(x,-5.024071e+00,tj,tj1,result);
   WCheb(x,-5.464515e+00,tj,tj1,result);
   WCheb(x,-1.278342e+00,tj,tj1,result);
   WCheb(x,-1.800030e-01,tj,tj1,result);
   WCheb(x,-4.046294e-02,tj,tj1,result);
   WCheb(x,-1.076162e-02,tj,tj1,result);
   WCheb(x,-3.968677e-03,tj,tj1,result);
   WCheb(x,-1.911679e-04,tj,tj1,result);
   WCheb(x,-8.619185e-04,tj,tj1,result);
   WCheb(x,5.125362e-04,tj,tj1,result);
   WCheb(x,-3.984370e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 40)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W40(const double s)
  {
//--- create variables
   double result=0;
   double x=0;
   double tj=0;
   double tj1=0;
//--- change values
   x=MathMin(2*(s-0.000000e+00)/4.000000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   WCheb(x,-4.904809e+00,tj,tj1,result);
   WCheb(x,-5.248327e+00,tj,tj1,result);
   WCheb(x,-1.136698e+00,tj,tj1,result);
   WCheb(x,-1.170982e-01,tj,tj1,result);
   WCheb(x,-1.824427e-02,tj,tj1,result);
   WCheb(x,-3.888648e-03,tj,tj1,result);
   WCheb(x,-1.344929e-03,tj,tj1,result);
   WCheb(x,2.790407e-04,tj,tj1,result);
   WCheb(x,-4.619858e-04,tj,tj1,result);
   WCheb(x,3.359121e-04,tj,tj1,result);
   WCheb(x,-2.883026e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 60)                                                      |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W60(const double s)
  {
//--- create variables
   double result=0;
   double x=0;
   double tj=0;
   double tj1=0;
//--- change values
   x=MathMin(2*(s-0.000000e+00)/4.000000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   WCheb(x,-4.809656e+00,tj,tj1,result);
   WCheb(x,-5.077191e+00,tj,tj1,result);
   WCheb(x,-1.029402e+00,tj,tj1,result);
   WCheb(x,-7.507931e-02,tj,tj1,result);
   WCheb(x,-6.506226e-03,tj,tj1,result);
   WCheb(x,-1.391278e-03,tj,tj1,result);
   WCheb(x,-4.263635e-04,tj,tj1,result);
   WCheb(x,2.302271e-04,tj,tj1,result);
   WCheb(x,-2.384348e-04,tj,tj1,result);
   WCheb(x,1.865587e-04,tj,tj1,result);
   WCheb(x,-1.622355e-04,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 120)                                                     |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W120(const double s)
  {
//--- create variables
   double result=0;
   double x=0;
   double tj=0;
   double tj1=0;
//--- change values
   x=MathMin(2*(s-0.000000e+00)/4.000000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   WCheb(x,-4.729426e+00,tj,tj1,result);
   WCheb(x,-4.934426e+00,tj,tj1,result);
   WCheb(x,-9.433231e-01,tj,tj1,result);
   WCheb(x,-4.492504e-02,tj,tj1,result);
   WCheb(x,1.673948e-05,tj,tj1,result);
   WCheb(x,-6.077014e-04,tj,tj1,result);
   WCheb(x,-7.215768e-05,tj,tj1,result);
   WCheb(x,9.086734e-05,tj,tj1,result);
   WCheb(x,-8.447980e-05,tj,tj1,result);
   WCheb(x,6.705028e-05,tj,tj1,result);
   WCheb(x,-5.828507e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S, 200)                                                     |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::W200(const double s)
  {
//--- create variables
   double result=0;
   double x=0;
   double tj=0;
   double tj1=0;
//--- change values
   x=MathMin(2*(s-0.000000e+00)/4.000000e+00-1,1.0);
   tj=1;
   tj1=x;
//--- interpolating
   WCheb(x,-4.700240e+00,tj,tj1,result);
   WCheb(x,-4.883080e+00,tj,tj1,result);
   WCheb(x,-9.132168e-01,tj,tj1,result);
   WCheb(x,-3.512684e-02,tj,tj1,result);
   WCheb(x,1.726342e-03,tj,tj1,result);
   WCheb(x,-5.189796e-04,tj,tj1,result);
   WCheb(x,-1.628659e-06,tj,tj1,result);
   WCheb(x,4.261786e-05,tj,tj1,result);
   WCheb(x,-4.002498e-05,tj,tj1,result);
   WCheb(x,3.146287e-05,tj,tj1,result);
   WCheb(x,-2.727576e-05,tj,tj1,result);
//--- return result
   return(result);
  }
//+------------------------------------------------------------------+
//| Tail(S,N), S>=0                                                  |
//+------------------------------------------------------------------+
static double CWilcoxonSignedRank::WSigma(const double s,const int n)
  {
//--- create variables
   double f0;
   double f1;
   double f2;
   double f3;
   double f4;
   double x0;
   double x1;
   double x2;
   double x3;
   double x4;
   double x;
//--- initialization
   f4=0;
//--- check
   if(n==5)
      return(W5(s));
//--- check
   if(n==6)
      return(W6(s));
//--- check
   if(n==7)
      return(W7(s));
//--- check
   if(n==8)
      return(W8(s));
//--- check
   if(n==9)
      return(W9(s));
//--- check
   if(n==10)
      return(W10(s));
//--- check
   if(n==11)
      return(W11(s));
//--- check
   if(n==12)
      return(W12(s));
//--- check
   if(n==13)
      return(W13(s));
//--- check
   if(n==14)
      return(W14(s));
//--- check
   if(n==15)
      return(W15(s));
//--- check
   if(n==16)
      return(W16(s));
//--- check
   if(n==17)
      return(W17(s));
//--- check
   if(n==18)
      return(W18(s));
//--- check
   if(n==19)
      return(W19(s));
//--- check
   if(n==20)
      return(W20(s));
//--- check
   if(n==21)
      return(W21(s));
//--- check
   if(n==22)
      return(W22(s));
//--- check
   if(n==23)
      return(W23(s));
//--- check
   if(n==24)
      return(W24(s));
//--- check
   if(n==25)
      return(W25(s));
//--- check
   if(n==26)
      return(W26(s));
//--- check
   if(n==27)
      return(W27(s));
//--- check
   if(n==28)
      return(W28(s));
//--- check
   if(n==29)
      return(W29(s));
//--- check
   if(n==30)
      return(W30(s));
//--- check
   if(n>30)
     {
      x=1.0/n;
      x0=1.0/30;
      f0=W30(s);
      x1=1.0/40;
      f1=W40(s);
      x2=1.0/60;
      f2=W60(s);
      x3=1.0/120;
      f3=W120(s);
      x4=1.0/200;
      f4=W200(s);
      //--- get result
      f1=((x-x0)*f1-(x-x1)*f0)/(x1-x0);
      f2=((x-x0)*f2-(x-x2)*f0)/(x2-x0);
      f3=((x-x0)*f3-(x-x3)*f0)/(x3-x0);
      f4=((x-x0)*f4-(x-x4)*f0)/(x4-x0);
      f2=((x-x1)*f2-(x-x2)*f1)/(x2-x1);
      f3=((x-x1)*f3-(x-x3)*f1)/(x3-x1);
      f4=((x-x1)*f4-(x-x4)*f1)/(x4-x1);
      f3=((x-x2)*f3-(x-x3)*f2)/(x3-x2);
      f4=((x-x2)*f4-(x-x4)*f2)/(x4-x2);
      f4=((x-x3)*f4-(x-x4)*f3)/(x4-x3);
     }
//--- return result
   return(f4);
  }
//+------------------------------------------------------------------+
