/* Include files */

#include "lab6_OnlineClassifier_sfun.h"
#include "c4_lab6_OnlineClassifier.h"
#include "mwmathutil.h"
#define _SF_MEX_LISTEN_FOR_CTRL_C(S)   sf_mex_listen_for_ctrl_c(S);
#ifdef utFree
#undef utFree
#endif

#ifdef utMalloc
#undef utMalloc
#endif

#ifdef __cplusplus

extern "C" void *utMalloc(size_t size);
extern "C" void utFree(void*);

#else

extern void *utMalloc(size_t size);
extern void utFree(void*);

#endif

/* Forward Declarations */

/* Type Definitions */

/* Named Constants */
#define CALL_EVENT                     (-1)

/* Variable Declarations */

/* Variable Definitions */
static real_T _sfTime_;
static emlrtMCInfo c4_emlrtMCI = { 14, /* lineNo */
  37,                                  /* colNo */
  "validatefinite",                    /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\eml\\eml\\+coder\\+internal\\+valattr\\validatefinite.m"/* pName */
};

static emlrtMCInfo c4_b_emlrtMCI = { 14,/* lineNo */
  37,                                  /* colNo */
  "validatenonnegative",               /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\eml\\eml\\+coder\\+internal\\+valattr\\validatenonnegative.m"/* pName */
};

static emlrtMCInfo c4_c_emlrtMCI = { 82,/* lineNo */
  5,                                   /* colNo */
  "power",                             /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\eml\\lib\\matlab\\ops\\power.m"/* pName */
};

static emlrtRSInfo c4_emlrtRSI = { 70, /* lineNo */
  "imbinarize",                        /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imbinarize.m"/* pathName */
};

static emlrtRSInfo c4_b_emlrtRSI = { 102,/* lineNo */
  "imbinarize",                        /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imbinarize.m"/* pathName */
};

static emlrtRSInfo c4_c_emlrtRSI = { 41,/* lineNo */
  "im2uint8",                          /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\im2uint8.m"/* pathName */
};

static emlrtRSInfo c4_d_emlrtRSI = { 197,/* lineNo */
  "im2uint8",                          /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\im2uint8.m"/* pathName */
};

static emlrtRSInfo c4_e_emlrtRSI = { 19,/* lineNo */
  "grayto8",                           /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\private\\grayto8.m"/* pathName */
};

static emlrtRSInfo c4_f_emlrtRSI = { 133,/* lineNo */
  "imhist",                            /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m"/* pathName */
};

static emlrtRSInfo c4_g_emlrtRSI = { 170,/* lineNo */
  "imhist",                            /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m"/* pathName */
};

static emlrtRSInfo c4_h_emlrtRSI = { 207,/* lineNo */
  "imhist",                            /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m"/* pathName */
};

static emlrtRSInfo c4_i_emlrtRSI = { 452,/* lineNo */
  "imhist",                            /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m"/* pathName */
};

static emlrtRSInfo c4_j_emlrtRSI = { 14,/* lineNo */
  "warning",                           /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\shared\\coder\\coder\\lib\\+coder\\+internal\\warning.m"/* pathName */
};

static emlrtRSInfo c4_k_emlrtRSI = { 37,/* lineNo */
  "otsuthresh",                        /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m"/* pathName */
};

static emlrtRSInfo c4_l_emlrtRSI = { 85,/* lineNo */
  "otsuthresh",                        /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m"/* pathName */
};

static emlrtRSInfo c4_m_emlrtRSI = { 93,/* lineNo */
  "validateattributes",                /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\eml\\lib\\matlab\\lang\\validateattributes.m"/* pathName */
};

static emlrtRSInfo c4_n_emlrtRSI = { 44,/* lineNo */
  "mpower",                            /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\eml\\lib\\matlab\\matfun\\mpower.m"/* pathName */
};

static emlrtRSInfo c4_o_emlrtRSI = { 71,/* lineNo */
  "power",                             /* fcnName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\eml\\lib\\matlab\\ops\\power.m"/* pathName */
};

static emlrtRSInfo c4_p_emlrtRSI = { 4,/* lineNo */
  "Hu Moments",                        /* fcnName */
  "#lab6_OnlineClassifier:307"         /* pathName */
};

static emlrtRSInfo c4_q_emlrtRSI = { 7,/* lineNo */
  "Hu Moments",                        /* fcnName */
  "#lab6_OnlineClassifier:307"         /* pathName */
};

static emlrtBCInfo c4_emlrtBCI = { 1,  /* iFirst */
  76800,                               /* iLast */
  1055,                                /* lineNo */
  48,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_emlrtDCI = { 1055,/* lineNo */
  48,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_b_emlrtBCI = { 1,/* iFirst */
  76800,                               /* iLast */
  1056,                                /* lineNo */
  48,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_b_emlrtDCI = { 1056,/* lineNo */
  48,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_c_emlrtBCI = { 1,/* iFirst */
  76800,                               /* iLast */
  1070,                                /* lineNo */
  47,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_c_emlrtDCI = { 1070,/* lineNo */
  47,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_d_emlrtBCI = { 1,/* iFirst */
  76800,                               /* iLast */
  1057,                                /* lineNo */
  48,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_d_emlrtDCI = { 1057,/* lineNo */
  48,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_e_emlrtBCI = { 1,/* iFirst */
  76800,                               /* iLast */
  1058,                                /* lineNo */
  48,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_e_emlrtDCI = { 1058,/* lineNo */
  48,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_f_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1134,                                /* lineNo */
  18,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_f_emlrtDCI = { 1134,/* lineNo */
  18,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_g_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1134,                                /* lineNo */
  34,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_g_emlrtDCI = { 1134,/* lineNo */
  34,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_h_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1134,                                /* lineNo */
  50,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_h_emlrtDCI = { 1134,/* lineNo */
  50,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_i_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1134,                                /* lineNo */
  66,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_i_emlrtDCI = { 1134,/* lineNo */
  66,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_j_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1134,                                /* lineNo */
  11,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  3                                    /* checkKind */
};

static emlrtDCInfo c4_j_emlrtDCI = { 1134,/* lineNo */
  11,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_k_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1072,                                /* lineNo */
  52,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_k_emlrtDCI = { 1072,/* lineNo */
  52,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_l_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1072,                                /* lineNo */
  15,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  3                                    /* checkKind */
};

static emlrtDCInfo c4_l_emlrtDCI = { 1072,/* lineNo */
  15,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_m_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1060,                                /* lineNo */
  71,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_m_emlrtDCI = { 1060,/* lineNo */
  71,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_n_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1060,                                /* lineNo */
  24,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  3                                    /* checkKind */
};

static emlrtDCInfo c4_n_emlrtDCI = { 1060,/* lineNo */
  24,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_o_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1061,                                /* lineNo */
  71,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_o_emlrtDCI = { 1061,/* lineNo */
  71,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_p_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1061,                                /* lineNo */
  24,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  3                                    /* checkKind */
};

static emlrtDCInfo c4_p_emlrtDCI = { 1061,/* lineNo */
  24,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_q_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1062,                                /* lineNo */
  71,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_q_emlrtDCI = { 1062,/* lineNo */
  71,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_r_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1062,                                /* lineNo */
  24,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  3                                    /* checkKind */
};

static emlrtDCInfo c4_r_emlrtDCI = { 1062,/* lineNo */
  24,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_s_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1063,                                /* lineNo */
  53,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_s_emlrtDCI = { 1063,/* lineNo */
  53,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_t_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  1063,                                /* lineNo */
  15,                                  /* colNo */
  "",                                  /* aName */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  3                                    /* checkKind */
};

static emlrtDCInfo c4_t_emlrtDCI = { 1063,/* lineNo */
  15,                                  /* colNo */
  "imhist",                            /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\imhist.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_u_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  54,                                  /* lineNo */
  47,                                  /* colNo */
  "",                                  /* aName */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_u_emlrtDCI = { 54,/* lineNo */
  47,                                  /* colNo */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_v_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  66,                                  /* lineNo */
  27,                                  /* colNo */
  "",                                  /* aName */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_v_emlrtDCI = { 66,/* lineNo */
  27,                                  /* colNo */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_w_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  68,                                  /* lineNo */
  26,                                  /* colNo */
  "",                                  /* aName */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_w_emlrtDCI = { 68,/* lineNo */
  26,                                  /* colNo */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_x_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  68,                                  /* lineNo */
  15,                                  /* colNo */
  "",                                  /* aName */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  3                                    /* checkKind */
};

static emlrtDCInfo c4_x_emlrtDCI = { 68,/* lineNo */
  15,                                  /* colNo */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_y_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  70,                                  /* lineNo */
  20,                                  /* colNo */
  "",                                  /* aName */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_y_emlrtDCI = { 70,/* lineNo */
  20,                                  /* colNo */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_ab_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  70,                                  /* lineNo */
  12,                                  /* colNo */
  "",                                  /* aName */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  3                                    /* checkKind */
};

static emlrtDCInfo c4_ab_emlrtDCI = { 70,/* lineNo */
  12,                                  /* colNo */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_bb_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  85,                                  /* lineNo */
  39,                                  /* colNo */
  "",                                  /* aName */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_bb_emlrtDCI = { 85,/* lineNo */
  39,                                  /* colNo */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_cb_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  85,                                  /* lineNo */
  47,                                  /* colNo */
  "",                                  /* aName */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_cb_emlrtDCI = { 85,/* lineNo */
  47,                                  /* colNo */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_db_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  85,                                  /* lineNo */
  62,                                  /* colNo */
  "",                                  /* aName */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_db_emlrtDCI = { 85,/* lineNo */
  62,                                  /* colNo */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  1                                    /* checkKind */
};

static emlrtBCInfo c4_eb_emlrtBCI = { 1,/* iFirst */
  256,                                 /* iLast */
  85,                                  /* lineNo */
  74,                                  /* colNo */
  "",                                  /* aName */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  0                                    /* checkKind */
};

static emlrtDCInfo c4_eb_emlrtDCI = { 85,/* lineNo */
  74,                                  /* colNo */
  "otsuthresh",                        /* fName */
  "C:\\Program Files\\MATLAB\\R2023a\\toolbox\\images\\images\\eml\\otsuthresh.m",/* pName */
  1                                    /* checkKind */
};

/* Function Declarations */
static void initialize_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static void initialize_params_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static void mdl_start_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static void mdl_terminate_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static void mdl_setup_runtime_resources_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static void mdl_cleanup_runtime_resources_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static void enable_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static void disable_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static void sf_gateway_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static void ext_mode_exec_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static void c4_update_jit_animation_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static void c4_do_animation_call_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static const mxArray *get_sim_state_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static void set_sim_state_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance, const mxArray *c4_st);
static void initSimStructsc4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static void initSubchartIOPointersc4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance);
static void c4_emlrt_marshallIn(SFc4_lab6_OnlineClassifierInstanceStruct
  *chartInstance, const mxArray *c4_outvar, const char_T *c4_identifier, real_T
  c4_y[7]);
static void c4_b_emlrt_marshallIn(SFc4_lab6_OnlineClassifierInstanceStruct
  *chartInstance, const mxArray *c4_u, const emlrtMsgIdentifier *c4_parentId,
  real_T c4_y[7]);
static uint8_T c4_c_emlrt_marshallIn(SFc4_lab6_OnlineClassifierInstanceStruct
  *chartInstance, const mxArray *c4_b_is_active_c4_lab6_OnlineClassifier, const
  char_T *c4_identifier);
static uint8_T c4_d_emlrt_marshallIn(SFc4_lab6_OnlineClassifierInstanceStruct
  *chartInstance, const mxArray *c4_u, const emlrtMsgIdentifier *c4_parentId);
static void c4_chart_data_browse_helper(SFc4_lab6_OnlineClassifierInstanceStruct
  *chartInstance, int32_T c4_ssIdNumber, const mxArray **c4_mxData, uint8_T
  *c4_isValueTooBig);
static const mxArray *c4_HuInvariantMoments
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance, const emlrtStack
   *c4_sp, const mxArray *c4_input0);
static void init_dsm_address_info(SFc4_lab6_OnlineClassifierInstanceStruct
  *chartInstance);
static void init_simulink_io_address(SFc4_lab6_OnlineClassifierInstanceStruct
  *chartInstance);

/* Function Definitions */
static void initialize_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  emlrtStack c4_st = { NULL,           /* site */
    NULL,                              /* tls */
    NULL                               /* prev */
  };

  c4_st.tls = chartInstance->c4_fEmlrtCtx;
  emlrtLicenseCheckR2022a(&c4_st, "EMLRT:runTime:MexFunctionNeedsLicense",
    "image_toolbox", 2);
  sim_mode_is_external(chartInstance->S);
  chartInstance->c4_sfEvent = CALL_EVENT;
  _sfTime_ = sf_get_time(chartInstance->S);
  chartInstance->c4_is_active_c4_lab6_OnlineClassifier = 0U;
}

static void initialize_params_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  (void)chartInstance;
}

static void mdl_start_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  sim_mode_is_external(chartInstance->S);
}

static void mdl_terminate_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  (void)chartInstance;
}

static void mdl_setup_runtime_resources_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  static const uint32_T c4_decisionTxtEndIdx = 0U;
  static const uint32_T c4_decisionTxtStartIdx = 0U;
  setDebuggerFlag(chartInstance->S, true);
  setDataBrowseFcn(chartInstance->S, (void *)&c4_chart_data_browse_helper);
  chartInstance->c4_RuntimeVar = sfListenerCacheSimStruct(chartInstance->S);
  sfListenerInitializeRuntimeVars(chartInstance->c4_RuntimeVar,
    &chartInstance->c4_IsDebuggerActive,
    &chartInstance->c4_IsSequenceViewerPresent, 0, 0,
    &chartInstance->c4_mlFcnLineNumber, &chartInstance->c4_IsHeatMapPresent, 0);
  covrtCreateStateflowInstanceData(chartInstance->c4_covrtInstance, 1U, 0U, 1U,
    25U);
  covrtChartInitFcn(chartInstance->c4_covrtInstance, 0U, false, false, false);
  covrtStateInitFcn(chartInstance->c4_covrtInstance, 0U, 0U, false, false, false,
                    0U, &c4_decisionTxtStartIdx, &c4_decisionTxtEndIdx);
  covrtTransInitFcn(chartInstance->c4_covrtInstance, 0U, 0, NULL, NULL, 0U, NULL);
  covrtEmlInitFcn(chartInstance->c4_covrtInstance, "", 4U, 0U, 1U, 0U, 0U, 0U,
                  0U, 0U, 0U, 0U, 0U, 0U);
  covrtEmlFcnInitFcn(chartInstance->c4_covrtInstance, 4U, 0U, 0U,
                     "eML_blk_kernel", 0, -1, 241);
}

static void mdl_cleanup_runtime_resources_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  sfListenerLightTerminate(chartInstance->c4_RuntimeVar);
  covrtDeleteStateflowInstanceData(chartInstance->c4_covrtInstance);
}

static void enable_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  _sfTime_ = sf_get_time(chartInstance->S);
}

static void disable_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  _sfTime_ = sf_get_time(chartInstance->S);
}

static void sf_gateway_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  static char_T c4_cv4[51] = { 'C', 'o', 'd', 'e', 'r', ':', 't', 'o', 'o', 'l',
    'b', 'o', 'x', ':', 'V', 'a', 'l', 'i', 'd', 'a', 't', 'e', 'a', 't', 't',
    'r', 'i', 'b', 'u', 't', 'e', 's', 'e', 'x', 'p', 'e', 'c', 't', 'e', 'd',
    'N', 'o', 'n', 'n', 'e', 'g', 'a', 't', 'i', 'v', 'e' };

  static char_T c4_cv1[46] = { 'C', 'o', 'd', 'e', 'r', ':', 't', 'o', 'o', 'l',
    'b', 'o', 'x', ':', 'V', 'a', 'l', 'i', 'd', 'a', 't', 'e', 'a', 't', 't',
    'r', 'i', 'b', 'u', 't', 'e', 's', 'e', 'x', 'p', 'e', 'c', 't', 'e', 'd',
    'F', 'i', 'n', 'i', 't', 'e' };

  static char_T c4_cv3[37] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'o', 't', 's',
    'u', 't', 'h', 'r', 'e', 's', 'h', ':', 'e', 'x', 'p', 'e', 'c', 't', 'e',
    'd', 'N', 'o', 'n', 'n', 'e', 'g', 'a', 't', 'i', 'v', 'e' };

  static char_T c4_cv[32] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'o', 't', 's',
    'u', 't', 'h', 'r', 'e', 's', 'h', ':', 'e', 'x', 'p', 'e', 'c', 't', 'e',
    'd', 'F', 'i', 'n', 'i', 't', 'e' };

  static char_T c4_cv2[6] = { 'C', 'O', 'U', 'N', 'T', 'S' };

  static char_T c4_cv5[6] = { 'C', 'O', 'U', 'N', 'T', 'S' };

  emlrtStack c4_b_st;
  emlrtStack c4_c_st;
  emlrtStack c4_d_st;
  emlrtStack c4_e_st;
  emlrtStack c4_f_st;
  emlrtStack c4_st = { NULL,           /* site */
    NULL,                              /* tls */
    NULL                               /* prev */
  };

  const mxArray *c4_b_y = NULL;
  const mxArray *c4_c_y = NULL;
  const mxArray *c4_d_y = NULL;
  const mxArray *c4_e_y = NULL;
  const mxArray *c4_f_y = NULL;
  const mxArray *c4_g_y = NULL;
  const mxArray *c4_h_y = NULL;
  const mxArray *c4_outvar = NULL;
  real_T c4_localBins1[256];
  real_T c4_localBins2[256];
  real_T c4_localBins3[256];
  real_T c4_y[256];
  real_T c4_dv[7];
  real_T c4_T;
  real_T c4_b_idx;
  real_T c4_b_k;
  real_T c4_b_x;
  real_T c4_c_x;
  real_T c4_d;
  real_T c4_d1;
  real_T c4_d10;
  real_T c4_d11;
  real_T c4_d12;
  real_T c4_d13;
  real_T c4_d14;
  real_T c4_d15;
  real_T c4_d16;
  real_T c4_d2;
  real_T c4_d3;
  real_T c4_d4;
  real_T c4_d5;
  real_T c4_d6;
  real_T c4_d7;
  real_T c4_d8;
  real_T c4_d9;
  real_T c4_d_i;
  real_T c4_d_k;
  real_T c4_d_p;
  real_T c4_d_x;
  real_T c4_e_x;
  real_T c4_f_k;
  real_T c4_f_x;
  real_T c4_g_a;
  real_T c4_g_c;
  real_T c4_g_x;
  real_T c4_h_a;
  real_T c4_i_a;
  real_T c4_j_a;
  real_T c4_k_a;
  real_T c4_maxval;
  real_T c4_mu_t;
  real_T c4_num_elems;
  real_T c4_num_maxval;
  real_T c4_out;
  real_T c4_sigma_b_squared;
  real_T c4_t;
  real_T c4_x;
  int32_T c4_a;
  int32_T c4_b_a;
  int32_T c4_b_c;
  int32_T c4_b_i;
  int32_T c4_c;
  int32_T c4_c_a;
  int32_T c4_c_c;
  int32_T c4_c_i;
  int32_T c4_c_k;
  int32_T c4_d_a;
  int32_T c4_d_c;
  int32_T c4_e_a;
  int32_T c4_e_c;
  int32_T c4_e_k;
  int32_T c4_f_a;
  int32_T c4_f_c;
  int32_T c4_g_k;
  int32_T c4_h_c;
  int32_T c4_h_k;
  int32_T c4_i;
  int32_T c4_i1;
  int32_T c4_i10;
  int32_T c4_i11;
  int32_T c4_i12;
  int32_T c4_i13;
  int32_T c4_i14;
  int32_T c4_i15;
  int32_T c4_i16;
  int32_T c4_i17;
  int32_T c4_i18;
  int32_T c4_i19;
  int32_T c4_i2;
  int32_T c4_i20;
  int32_T c4_i21;
  int32_T c4_i22;
  int32_T c4_i23;
  int32_T c4_i24;
  int32_T c4_i25;
  int32_T c4_i26;
  int32_T c4_i27;
  int32_T c4_i28;
  int32_T c4_i29;
  int32_T c4_i3;
  int32_T c4_i30;
  int32_T c4_i31;
  int32_T c4_i32;
  int32_T c4_i33;
  int32_T c4_i34;
  int32_T c4_i35;
  int32_T c4_i36;
  int32_T c4_i37;
  int32_T c4_i38;
  int32_T c4_i4;
  int32_T c4_i5;
  int32_T c4_i6;
  int32_T c4_i7;
  int32_T c4_i8;
  int32_T c4_i9;
  int32_T c4_i_c;
  int32_T c4_idx;
  int32_T c4_idx1;
  int32_T c4_idx2;
  int32_T c4_idx3;
  int32_T c4_idx4;
  int32_T c4_j_c;
  int32_T c4_k;
  int32_T c4_k_c;
  int32_T c4_l_a;
  int32_T c4_m_a;
  int32_T c4_n_a;
  int32_T c4_o_a;
  uint8_T c4_u[76800];
  boolean_T c4_A[76800];
  boolean_T c4_b;
  boolean_T c4_b1;
  boolean_T c4_b2;
  boolean_T c4_b3;
  boolean_T c4_b4;
  boolean_T c4_b5;
  boolean_T c4_b_b;
  boolean_T c4_b_p;
  boolean_T c4_c_b;
  boolean_T c4_c_p;
  boolean_T c4_d_b;
  boolean_T c4_e_b;
  boolean_T c4_exitg1;
  boolean_T c4_f_b;
  boolean_T c4_isfinite_maxval;
  boolean_T c4_p;
  c4_st.tls = chartInstance->c4_fEmlrtCtx;
  c4_b_st.prev = &c4_st;
  c4_b_st.tls = c4_st.tls;
  c4_c_st.prev = &c4_b_st;
  c4_c_st.tls = c4_b_st.tls;
  c4_d_st.prev = &c4_c_st;
  c4_d_st.tls = c4_c_st.tls;
  c4_e_st.prev = &c4_d_st;
  c4_e_st.tls = c4_d_st.tls;
  c4_f_st.prev = &c4_e_st;
  c4_f_st.tls = c4_e_st.tls;
  chartInstance->c4_JITTransitionAnimation[0] = 0U;
  _sfTime_ = sf_get_time(chartInstance->S);
  if (covrtIsSigCovEnabledFcn(chartInstance->c4_covrtInstance, 0U) != 0U) {
    for (c4_i = 0; c4_i < 76800; c4_i++) {
      covrtSigUpdateFcnAssumingCovEnabled(chartInstance->c4_covrtInstance, 0U, (*
        chartInstance->c4_img)[c4_i]);
    }
  }

  chartInstance->c4_sfEvent = CALL_EVENT;
  covrtEmlFcnEval(chartInstance->c4_covrtInstance, 4U, 0, 0);
  c4_b_st.site = &c4_p_emlrtRSI;
  c4_c_st.site = &c4_emlrtRSI;
  c4_d_st.site = &c4_b_emlrtRSI;
  c4_e_st.site = &c4_c_emlrtRSI;
  c4_f_st.site = &c4_d_emlrtRSI;
  grayto8_real64(&(*chartInstance->c4_img)[0], &c4_u[0], 76800.0);
  c4_d_st.site = &c4_b_emlrtRSI;
  c4_e_st.site = &c4_f_emlrtRSI;
  c4_f_st.site = &c4_g_emlrtRSI;
  c4_out = 1.0;
  getnumcores(&c4_out);
  c4_f_st.site = &c4_h_emlrtRSI;
  for (c4_i1 = 0; c4_i1 < 256; c4_i1++) {
    c4_y[c4_i1] = 0.0;
  }

  for (c4_i2 = 0; c4_i2 < 256; c4_i2++) {
    c4_localBins1[c4_i2] = 0.0;
  }

  for (c4_i3 = 0; c4_i3 < 256; c4_i3++) {
    c4_localBins2[c4_i3] = 0.0;
  }

  for (c4_i4 = 0; c4_i4 < 256; c4_i4++) {
    c4_localBins3[c4_i4] = 0.0;
  }

  for (c4_b_i = 1; c4_b_i + 3 <= 76800; c4_b_i += 4) {
    c4_d = (real_T)c4_b_i;
    if (c4_d != (real_T)(int32_T)muDoubleScalarFloor(c4_d)) {
      emlrtIntegerCheckR2012b(c4_d, &c4_emlrtDCI, &c4_f_st);
    }

    c4_i5 = (int32_T)muDoubleScalarFloor(c4_d);
    if ((c4_i5 < 1) || (c4_i5 > 76800)) {
      emlrtDynamicBoundsCheckR2012b(c4_i5, 1, 76800, &c4_emlrtBCI, &c4_f_st);
    }

    c4_idx1 = c4_u[c4_i5 - 1];
    c4_d2 = (real_T)(c4_b_i + 1);
    if (c4_d2 != (real_T)(int32_T)muDoubleScalarFloor(c4_d2)) {
      emlrtIntegerCheckR2012b(c4_d2, &c4_b_emlrtDCI, &c4_f_st);
    }

    c4_i8 = (int32_T)muDoubleScalarFloor(c4_d2);
    if ((c4_i8 < 1) || (c4_i8 > 76800)) {
      emlrtDynamicBoundsCheckR2012b(c4_i8, 1, 76800, &c4_b_emlrtBCI, &c4_f_st);
    }

    c4_idx2 = c4_u[c4_i8 - 1];
    c4_d4 = (real_T)(c4_b_i + 2);
    if (c4_d4 != (real_T)(int32_T)muDoubleScalarFloor(c4_d4)) {
      emlrtIntegerCheckR2012b(c4_d4, &c4_d_emlrtDCI, &c4_f_st);
    }

    c4_i12 = (int32_T)muDoubleScalarFloor(c4_d4);
    if ((c4_i12 < 1) || (c4_i12 > 76800)) {
      emlrtDynamicBoundsCheckR2012b(c4_i12, 1, 76800, &c4_d_emlrtBCI, &c4_f_st);
    }

    c4_idx3 = c4_u[c4_i12 - 1];
    c4_d6 = (real_T)(c4_b_i + 3);
    if (c4_d6 != (real_T)(int32_T)muDoubleScalarFloor(c4_d6)) {
      emlrtIntegerCheckR2012b(c4_d6, &c4_e_emlrtDCI, &c4_f_st);
    }

    c4_i15 = (int32_T)muDoubleScalarFloor(c4_d6);
    if ((c4_i15 < 1) || (c4_i15 > 76800)) {
      emlrtDynamicBoundsCheckR2012b(c4_i15, 1, 76800, &c4_e_emlrtBCI, &c4_f_st);
    }

    c4_idx4 = c4_u[c4_i15 - 1];
    c4_c_a = c4_idx1 + 1;
    c4_c_c = c4_c_a;
    c4_d_a = c4_idx1 + 1;
    c4_d_c = c4_d_a;
    c4_d7 = (real_T)c4_d_c;
    if (c4_d7 != (real_T)(int32_T)muDoubleScalarFloor(c4_d7)) {
      emlrtIntegerCheckR2012b(c4_d7, &c4_m_emlrtDCI, &c4_f_st);
    }

    c4_i18 = (int32_T)muDoubleScalarFloor(c4_d7);
    if ((c4_i18 < 1) || (c4_i18 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i18, 1, 256, &c4_m_emlrtBCI, &c4_f_st);
    }

    c4_d8 = (real_T)c4_c_c;
    if (c4_d8 != (real_T)(int32_T)muDoubleScalarFloor(c4_d8)) {
      emlrtIntegerCheckR2012b(c4_d8, &c4_n_emlrtDCI, &c4_f_st);
    }

    c4_i20 = (int32_T)muDoubleScalarFloor(c4_d8);
    if ((c4_i20 < 1) || (c4_i20 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i20, 1, 256, &c4_n_emlrtBCI, &c4_f_st);
    }

    c4_localBins1[c4_i20 - 1] = c4_localBins1[c4_i18 - 1] + 1.0;
    c4_e_a = c4_idx2 + 1;
    c4_e_c = c4_e_a;
    c4_f_a = c4_idx2 + 1;
    c4_f_c = c4_f_a;
    c4_d10 = (real_T)c4_f_c;
    if (c4_d10 != (real_T)(int32_T)muDoubleScalarFloor(c4_d10)) {
      emlrtIntegerCheckR2012b(c4_d10, &c4_o_emlrtDCI, &c4_f_st);
    }

    c4_i25 = (int32_T)muDoubleScalarFloor(c4_d10);
    if ((c4_i25 < 1) || (c4_i25 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i25, 1, 256, &c4_o_emlrtBCI, &c4_f_st);
    }

    c4_d12 = (real_T)c4_e_c;
    if (c4_d12 != (real_T)(int32_T)muDoubleScalarFloor(c4_d12)) {
      emlrtIntegerCheckR2012b(c4_d12, &c4_p_emlrtDCI, &c4_f_st);
    }

    c4_i29 = (int32_T)muDoubleScalarFloor(c4_d12);
    if ((c4_i29 < 1) || (c4_i29 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i29, 1, 256, &c4_p_emlrtBCI, &c4_f_st);
    }

    c4_localBins2[c4_i29 - 1] = c4_localBins2[c4_i25 - 1] + 1.0;
    c4_l_a = c4_idx3 + 1;
    c4_h_c = c4_l_a;
    c4_m_a = c4_idx3 + 1;
    c4_i_c = c4_m_a;
    c4_d13 = (real_T)c4_i_c;
    if (c4_d13 != (real_T)(int32_T)muDoubleScalarFloor(c4_d13)) {
      emlrtIntegerCheckR2012b(c4_d13, &c4_q_emlrtDCI, &c4_f_st);
    }

    c4_i35 = (int32_T)muDoubleScalarFloor(c4_d13);
    if ((c4_i35 < 1) || (c4_i35 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i35, 1, 256, &c4_q_emlrtBCI, &c4_f_st);
    }

    c4_d14 = (real_T)c4_h_c;
    if (c4_d14 != (real_T)(int32_T)muDoubleScalarFloor(c4_d14)) {
      emlrtIntegerCheckR2012b(c4_d14, &c4_r_emlrtDCI, &c4_f_st);
    }

    c4_i36 = (int32_T)muDoubleScalarFloor(c4_d14);
    if ((c4_i36 < 1) || (c4_i36 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i36, 1, 256, &c4_r_emlrtBCI, &c4_f_st);
    }

    c4_localBins3[c4_i36 - 1] = c4_localBins3[c4_i35 - 1] + 1.0;
    c4_n_a = c4_idx4 + 1;
    c4_j_c = c4_n_a;
    c4_o_a = c4_idx4 + 1;
    c4_k_c = c4_o_a;
    c4_d15 = (real_T)c4_k_c;
    if (c4_d15 != (real_T)(int32_T)muDoubleScalarFloor(c4_d15)) {
      emlrtIntegerCheckR2012b(c4_d15, &c4_s_emlrtDCI, &c4_f_st);
    }

    c4_i37 = (int32_T)muDoubleScalarFloor(c4_d15);
    if ((c4_i37 < 1) || (c4_i37 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i37, 1, 256, &c4_s_emlrtBCI, &c4_f_st);
    }

    c4_d16 = (real_T)c4_j_c;
    if (c4_d16 != (real_T)(int32_T)muDoubleScalarFloor(c4_d16)) {
      emlrtIntegerCheckR2012b(c4_d16, &c4_t_emlrtDCI, &c4_f_st);
    }

    c4_i38 = (int32_T)muDoubleScalarFloor(c4_d16);
    if ((c4_i38 < 1) || (c4_i38 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i38, 1, 256, &c4_t_emlrtBCI, &c4_f_st);
    }

    c4_y[c4_i38 - 1] = c4_y[c4_i37 - 1] + 1.0;
  }

  while (c4_b_i <= 76800) {
    c4_d1 = (real_T)c4_b_i;
    if (c4_d1 != (real_T)(int32_T)muDoubleScalarFloor(c4_d1)) {
      emlrtIntegerCheckR2012b(c4_d1, &c4_c_emlrtDCI, &c4_f_st);
    }

    c4_i6 = (int32_T)muDoubleScalarFloor(c4_d1);
    if ((c4_i6 < 1) || (c4_i6 > 76800)) {
      emlrtDynamicBoundsCheckR2012b(c4_i6, 1, 76800, &c4_c_emlrtBCI, &c4_f_st);
    }

    c4_idx = c4_u[c4_i6 - 1];
    c4_a = c4_idx + 1;
    c4_c = c4_a;
    c4_b_a = c4_idx + 1;
    c4_b_c = c4_b_a;
    c4_d3 = (real_T)c4_b_c;
    if (c4_d3 != (real_T)(int32_T)muDoubleScalarFloor(c4_d3)) {
      emlrtIntegerCheckR2012b(c4_d3, &c4_k_emlrtDCI, &c4_f_st);
    }

    c4_i10 = (int32_T)muDoubleScalarFloor(c4_d3);
    if ((c4_i10 < 1) || (c4_i10 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i10, 1, 256, &c4_k_emlrtBCI, &c4_f_st);
    }

    c4_d5 = (real_T)c4_c;
    if (c4_d5 != (real_T)(int32_T)muDoubleScalarFloor(c4_d5)) {
      emlrtIntegerCheckR2012b(c4_d5, &c4_l_emlrtDCI, &c4_f_st);
    }

    c4_i14 = (int32_T)muDoubleScalarFloor(c4_d5);
    if ((c4_i14 < 1) || (c4_i14 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i14, 1, 256, &c4_l_emlrtBCI, &c4_f_st);
    }

    c4_y[c4_i14 - 1] = c4_y[c4_i10 - 1] + 1.0;
    c4_b_i++;
  }

  for (c4_c_i = 0; c4_c_i < 256; c4_c_i++) {
    c4_d_i = 1.0 + (real_T)c4_c_i;
    if (c4_d_i != (real_T)(int32_T)muDoubleScalarFloor(c4_d_i)) {
      emlrtIntegerCheckR2012b(c4_d_i, &c4_f_emlrtDCI, &c4_f_st);
    }

    c4_i7 = (int32_T)c4_d_i;
    if ((c4_i7 < 1) || (c4_i7 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i7, 1, 256, &c4_f_emlrtBCI, &c4_f_st);
    }

    if (c4_d_i != (real_T)(int32_T)muDoubleScalarFloor(c4_d_i)) {
      emlrtIntegerCheckR2012b(c4_d_i, &c4_g_emlrtDCI, &c4_f_st);
    }

    c4_i9 = (int32_T)c4_d_i;
    if ((c4_i9 < 1) || (c4_i9 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i9, 1, 256, &c4_g_emlrtBCI, &c4_f_st);
    }

    if (c4_d_i != (real_T)(int32_T)muDoubleScalarFloor(c4_d_i)) {
      emlrtIntegerCheckR2012b(c4_d_i, &c4_h_emlrtDCI, &c4_f_st);
    }

    c4_i11 = (int32_T)c4_d_i;
    if ((c4_i11 < 1) || (c4_i11 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i11, 1, 256, &c4_h_emlrtBCI, &c4_f_st);
    }

    if (c4_d_i != (real_T)(int32_T)muDoubleScalarFloor(c4_d_i)) {
      emlrtIntegerCheckR2012b(c4_d_i, &c4_i_emlrtDCI, &c4_f_st);
    }

    c4_i13 = (int32_T)c4_d_i;
    if ((c4_i13 < 1) || (c4_i13 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i13, 1, 256, &c4_i_emlrtBCI, &c4_f_st);
    }

    if (c4_d_i != (real_T)(int32_T)muDoubleScalarFloor(c4_d_i)) {
      emlrtIntegerCheckR2012b(c4_d_i, &c4_j_emlrtDCI, &c4_f_st);
    }

    c4_i16 = (int32_T)c4_d_i;
    if ((c4_i16 < 1) || (c4_i16 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i16, 1, 256, &c4_j_emlrtBCI, &c4_f_st);
    }

    c4_y[c4_i16 - 1] = ((c4_y[c4_i7 - 1] + c4_localBins1[c4_i9 - 1]) +
                        c4_localBins2[c4_i11 - 1]) + c4_localBins3[c4_i13 - 1];
  }

  c4_d_st.site = &c4_b_emlrtRSI;
  c4_e_st.site = &c4_k_emlrtRSI;
  c4_f_st.site = &c4_m_emlrtRSI;
  c4_p = true;
  c4_k = 0;
  c4_exitg1 = false;
  while ((!c4_exitg1) && (c4_k < 256)) {
    c4_b_k = 1.0 + (real_T)c4_k;
    c4_x = c4_y[(int32_T)c4_b_k - 1];
    c4_b_x = c4_x;
    c4_b_b = muDoubleScalarIsInf(c4_b_x);
    c4_b1 = !c4_b_b;
    c4_c_x = c4_x;
    c4_c_b = muDoubleScalarIsNaN(c4_c_x);
    c4_b2 = !c4_c_b;
    c4_d_b = (c4_b1 && c4_b2);
    if (c4_d_b) {
      c4_k++;
    } else {
      c4_p = false;
      c4_exitg1 = true;
    }
  }

  if (c4_p) {
    c4_b = true;
  } else {
    c4_b = false;
  }

  if (!c4_b) {
    c4_b_y = NULL;
    sf_mex_assign(&c4_b_y, sf_mex_create("y", c4_cv, 10, 0U, 1U, 0U, 2, 1, 32),
                  false);
    c4_c_y = NULL;
    sf_mex_assign(&c4_c_y, sf_mex_create("y", c4_cv1, 10, 0U, 1U, 0U, 2, 1, 46),
                  false);
    c4_d_y = NULL;
    sf_mex_assign(&c4_d_y, sf_mex_create("y", c4_cv2, 10, 0U, 1U, 0U, 2, 1, 6),
                  false);
    sf_mex_call(&c4_f_st, &c4_emlrtMCI, "error", 0U, 2U, 14, c4_b_y, 14,
                sf_mex_call(&c4_f_st, NULL, "getString", 1U, 1U, 14, sf_mex_call
      (&c4_f_st, NULL, "message", 1U, 2U, 14, c4_c_y, 14, c4_d_y)));
  }

  c4_f_st.site = &c4_m_emlrtRSI;
  c4_b_p = true;
  c4_c_k = 0;
  c4_exitg1 = false;
  while ((!c4_exitg1) && (c4_c_k < 256)) {
    c4_d_k = 1.0 + (real_T)c4_c_k;
    c4_d_x = c4_y[(int32_T)c4_d_k - 1];
    c4_c_p = !(c4_d_x < 0.0);
    if (c4_c_p) {
      c4_c_k++;
    } else {
      c4_b_p = false;
      c4_exitg1 = true;
    }
  }

  if (c4_b_p) {
    c4_b3 = true;
  } else {
    c4_b3 = false;
  }

  if (!c4_b3) {
    c4_e_y = NULL;
    sf_mex_assign(&c4_e_y, sf_mex_create("y", c4_cv3, 10, 0U, 1U, 0U, 2, 1, 37),
                  false);
    c4_f_y = NULL;
    sf_mex_assign(&c4_f_y, sf_mex_create("y", c4_cv4, 10, 0U, 1U, 0U, 2, 1, 51),
                  false);
    c4_g_y = NULL;
    sf_mex_assign(&c4_g_y, sf_mex_create("y", c4_cv5, 10, 0U, 1U, 0U, 2, 1, 6),
                  false);
    sf_mex_call(&c4_f_st, &c4_b_emlrtMCI, "error", 0U, 2U, 14, c4_e_y, 14,
                sf_mex_call(&c4_f_st, NULL, "getString", 1U, 1U, 14, sf_mex_call
      (&c4_f_st, NULL, "message", 1U, 2U, 14, c4_f_y, 14, c4_g_y)));
  }

  c4_num_elems = 0.0;
  for (c4_e_k = 0; c4_e_k < 256; c4_e_k++) {
    c4_f_k = 1.0 + (real_T)c4_e_k;
    if (c4_f_k != (real_T)(int32_T)muDoubleScalarFloor(c4_f_k)) {
      emlrtIntegerCheckR2012b(c4_f_k, &c4_u_emlrtDCI, &c4_d_st);
    }

    c4_i17 = (int32_T)c4_f_k;
    if ((c4_i17 < 1) || (c4_i17 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i17, 1, 256, &c4_u_emlrtBCI, &c4_d_st);
    }

    c4_num_elems += c4_y[c4_i17 - 1];
  }

  c4_localBins1[0] = c4_y[0] / c4_num_elems;
  c4_localBins2[0] = c4_localBins1[0];
  for (c4_g_k = 0; c4_g_k < 255; c4_g_k++) {
    c4_f_k = 2.0 + (real_T)c4_g_k;
    if (c4_f_k != (real_T)(int32_T)muDoubleScalarFloor(c4_f_k)) {
      emlrtIntegerCheckR2012b(c4_f_k, &c4_v_emlrtDCI, &c4_d_st);
    }

    c4_i19 = (int32_T)c4_f_k;
    if ((c4_i19 < 1) || (c4_i19 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i19, 1, 256, &c4_v_emlrtBCI, &c4_d_st);
    }

    c4_d_p = c4_y[c4_i19 - 1] / c4_num_elems;
    c4_d9 = c4_f_k - 1.0;
    if (c4_d9 != (real_T)(int32_T)muDoubleScalarFloor(c4_d9)) {
      emlrtIntegerCheckR2012b(c4_d9, &c4_w_emlrtDCI, &c4_d_st);
    }

    c4_i22 = (int32_T)c4_d9;
    if ((c4_i22 < 1) || (c4_i22 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i22, 1, 256, &c4_w_emlrtBCI, &c4_d_st);
    }

    if (c4_f_k != (real_T)(int32_T)muDoubleScalarFloor(c4_f_k)) {
      emlrtIntegerCheckR2012b(c4_f_k, &c4_x_emlrtDCI, &c4_d_st);
    }

    c4_i24 = (int32_T)c4_f_k;
    if ((c4_i24 < 1) || (c4_i24 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i24, 1, 256, &c4_x_emlrtBCI, &c4_d_st);
    }

    c4_localBins1[c4_i24 - 1] = c4_localBins1[c4_i22 - 1] + c4_d_p;
    c4_d11 = c4_f_k - 1.0;
    if (c4_d11 != (real_T)(int32_T)muDoubleScalarFloor(c4_d11)) {
      emlrtIntegerCheckR2012b(c4_d11, &c4_y_emlrtDCI, &c4_d_st);
    }

    c4_i28 = (int32_T)c4_d11;
    if ((c4_i28 < 1) || (c4_i28 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i28, 1, 256, &c4_y_emlrtBCI, &c4_d_st);
    }

    if (c4_f_k != (real_T)(int32_T)muDoubleScalarFloor(c4_f_k)) {
      emlrtIntegerCheckR2012b(c4_f_k, &c4_ab_emlrtDCI, &c4_d_st);
    }

    c4_i32 = (int32_T)c4_f_k;
    if ((c4_i32 < 1) || (c4_i32 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i32, 1, 256, &c4_ab_emlrtBCI, &c4_d_st);
    }

    c4_localBins2[c4_i32 - 1] = c4_localBins2[c4_i28 - 1] + c4_d_p * c4_f_k;
  }

  c4_mu_t = c4_localBins2[255];
  c4_maxval = rtMinusInf;
  c4_b_idx = 0.0;
  c4_num_maxval = 0.0;
  for (c4_h_k = 0; c4_h_k < 255; c4_h_k++) {
    c4_f_k = 1.0 + (real_T)c4_h_k;
    c4_e_st.site = &c4_l_emlrtRSI;
    if (c4_f_k != (real_T)(int32_T)muDoubleScalarFloor(c4_f_k)) {
      emlrtIntegerCheckR2012b(c4_f_k, &c4_bb_emlrtDCI, &c4_e_st);
    }

    c4_i21 = (int32_T)c4_f_k;
    if ((c4_i21 < 1) || (c4_i21 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i21, 1, 256, &c4_bb_emlrtBCI, &c4_e_st);
    }

    if (c4_f_k != (real_T)(int32_T)muDoubleScalarFloor(c4_f_k)) {
      emlrtIntegerCheckR2012b(c4_f_k, &c4_cb_emlrtDCI, &c4_e_st);
    }

    c4_i23 = (int32_T)c4_f_k;
    if ((c4_i23 < 1) || (c4_i23 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i23, 1, 256, &c4_cb_emlrtBCI, &c4_e_st);
    }

    c4_g_a = c4_mu_t * c4_localBins1[c4_i21 - 1] - c4_localBins2[c4_i23 - 1];
    c4_f_st.site = &c4_n_emlrtRSI;
    c4_h_a = c4_g_a;
    c4_i_a = c4_h_a;
    c4_j_a = c4_i_a;
    c4_k_a = c4_j_a;
    c4_g_c = c4_k_a * c4_k_a;
    if (c4_f_k != (real_T)(int32_T)muDoubleScalarFloor(c4_f_k)) {
      emlrtIntegerCheckR2012b(c4_f_k, &c4_db_emlrtDCI, &c4_d_st);
    }

    c4_i31 = (int32_T)c4_f_k;
    if ((c4_i31 < 1) || (c4_i31 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i31, 1, 256, &c4_db_emlrtBCI, &c4_d_st);
    }

    if (c4_f_k != (real_T)(int32_T)muDoubleScalarFloor(c4_f_k)) {
      emlrtIntegerCheckR2012b(c4_f_k, &c4_eb_emlrtDCI, &c4_d_st);
    }

    c4_i34 = (int32_T)c4_f_k;
    if ((c4_i34 < 1) || (c4_i34 > 256)) {
      emlrtDynamicBoundsCheckR2012b(c4_i34, 1, 256, &c4_eb_emlrtBCI, &c4_d_st);
    }

    c4_sigma_b_squared = c4_g_c / (c4_localBins1[c4_i31 - 1] * (1.0 -
      c4_localBins1[c4_i34 - 1]));
    if (c4_sigma_b_squared > c4_maxval) {
      c4_maxval = c4_sigma_b_squared;
      c4_b_idx = c4_f_k;
      c4_num_maxval = 1.0;
    } else if (c4_sigma_b_squared == c4_maxval) {
      c4_b_idx += c4_f_k;
      c4_num_maxval++;
    }
  }

  c4_e_x = c4_maxval;
  c4_f_x = c4_e_x;
  c4_e_b = muDoubleScalarIsInf(c4_f_x);
  c4_b4 = !c4_e_b;
  c4_g_x = c4_e_x;
  c4_f_b = muDoubleScalarIsNaN(c4_g_x);
  c4_b5 = !c4_f_b;
  c4_isfinite_maxval = (c4_b4 && c4_b5);
  if (c4_isfinite_maxval) {
    c4_b_idx /= c4_num_maxval;
    c4_t = (c4_b_idx - 1.0) / 255.0;
  } else {
    c4_t = 0.0;
  }

  c4_T = c4_t;
  for (c4_i26 = 0; c4_i26 < 76800; c4_i26++) {
    c4_A[c4_i26] = ((*chartInstance->c4_img)[c4_i26] > c4_T);
  }

  for (c4_i27 = 0; c4_i27 < 76800; c4_i27++) {
    c4_A[c4_i27] = !c4_A[c4_i27];
  }

  c4_h_y = NULL;
  sf_mex_assign(&c4_h_y, sf_mex_create("y", c4_A, 11, 0U, 1U, 0U, 2, 240, 320),
                false);
  c4_b_st.site = &c4_q_emlrtRSI;
  sf_mex_assign(&c4_outvar, c4_HuInvariantMoments(chartInstance, &c4_b_st,
    c4_h_y), false);
  c4_emlrt_marshallIn(chartInstance, sf_mex_dup(c4_outvar), "outvar", c4_dv);
  for (c4_i30 = 0; c4_i30 < 7; c4_i30++) {
    (*chartInstance->c4_M)[c4_i30] = c4_dv[c4_i30];
  }

  sf_mex_destroy(&c4_outvar);
  c4_do_animation_call_c4_lab6_OnlineClassifier(chartInstance);
  if (covrtIsSigCovEnabledFcn(chartInstance->c4_covrtInstance, 1U) != 0U) {
    for (c4_i33 = 0; c4_i33 < 7; c4_i33++) {
      covrtSigUpdateFcnAssumingCovEnabled(chartInstance->c4_covrtInstance, 1U, (*
        chartInstance->c4_M)[c4_i33]);
    }
  }
}

static void ext_mode_exec_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  (void)chartInstance;
}

static void c4_update_jit_animation_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  (void)chartInstance;
}

static void c4_do_animation_call_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  sfDoAnimationWrapper(chartInstance->S, false, true);
  sfDoAnimationWrapper(chartInstance->S, false, false);
}

static const mxArray *get_sim_state_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  const mxArray *c4_b_y = NULL;
  const mxArray *c4_c_y = NULL;
  const mxArray *c4_st;
  const mxArray *c4_y = NULL;
  c4_st = NULL;
  c4_st = NULL;
  c4_y = NULL;
  sf_mex_assign(&c4_y, sf_mex_createcellmatrix(2, 1), false);
  c4_b_y = NULL;
  sf_mex_assign(&c4_b_y, sf_mex_create("y", *chartInstance->c4_M, 0, 0U, 1U, 0U,
    1, 7), false);
  sf_mex_setcell(c4_y, 0, c4_b_y);
  c4_c_y = NULL;
  sf_mex_assign(&c4_c_y, sf_mex_create("y",
    &chartInstance->c4_is_active_c4_lab6_OnlineClassifier, 3, 0U, 0U, 0U, 0),
                false);
  sf_mex_setcell(c4_y, 1, c4_c_y);
  sf_mex_assign(&c4_st, c4_y, false);
  return c4_st;
}

static void set_sim_state_c4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance, const mxArray *c4_st)
{
  const mxArray *c4_u;
  real_T c4_dv[7];
  int32_T c4_i;
  chartInstance->c4_doneDoubleBufferReInit = true;
  c4_u = sf_mex_dup(c4_st);
  c4_emlrt_marshallIn(chartInstance, sf_mex_dup(sf_mex_getcell(c4_u, 0)), "M",
                      c4_dv);
  for (c4_i = 0; c4_i < 7; c4_i++) {
    (*chartInstance->c4_M)[c4_i] = c4_dv[c4_i];
  }

  chartInstance->c4_is_active_c4_lab6_OnlineClassifier = c4_c_emlrt_marshallIn
    (chartInstance, sf_mex_dup(sf_mex_getcell(c4_u, 1)),
     "is_active_c4_lab6_OnlineClassifier");
  sf_mex_destroy(&c4_u);
  sf_mex_destroy(&c4_st);
}

static void initSimStructsc4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  (void)chartInstance;
}

static void initSubchartIOPointersc4_lab6_OnlineClassifier
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance)
{
  (void)chartInstance;
}

const mxArray *sf_c4_lab6_OnlineClassifier_get_eml_resolved_functions_info(void)
{
  const mxArray *c4_nameCaptureInfo = NULL;
  c4_nameCaptureInfo = NULL;
  sf_mex_assign(&c4_nameCaptureInfo, sf_mex_create("nameCaptureInfo", NULL, 0,
    0U, 1U, 0U, 2, 0, 1), false);
  return c4_nameCaptureInfo;
}

static void c4_emlrt_marshallIn(SFc4_lab6_OnlineClassifierInstanceStruct
  *chartInstance, const mxArray *c4_outvar, const char_T *c4_identifier, real_T
  c4_y[7])
{
  emlrtMsgIdentifier c4_thisId;
  c4_thisId.fIdentifier = (const char_T *)c4_identifier;
  c4_thisId.fParent = NULL;
  c4_thisId.bParentIsCell = false;
  c4_b_emlrt_marshallIn(chartInstance, sf_mex_dup(c4_outvar), &c4_thisId, c4_y);
  sf_mex_destroy(&c4_outvar);
}

static void c4_b_emlrt_marshallIn(SFc4_lab6_OnlineClassifierInstanceStruct
  *chartInstance, const mxArray *c4_u, const emlrtMsgIdentifier *c4_parentId,
  real_T c4_y[7])
{
  real_T c4_dv[7];
  int32_T c4_i;
  (void)chartInstance;
  sf_mex_import(c4_parentId, sf_mex_dup(c4_u), c4_dv, 1, 0, 0U, 1, 0U, 1, 7);
  for (c4_i = 0; c4_i < 7; c4_i++) {
    c4_y[c4_i] = c4_dv[c4_i];
  }

  sf_mex_destroy(&c4_u);
}

static uint8_T c4_c_emlrt_marshallIn(SFc4_lab6_OnlineClassifierInstanceStruct
  *chartInstance, const mxArray *c4_b_is_active_c4_lab6_OnlineClassifier, const
  char_T *c4_identifier)
{
  emlrtMsgIdentifier c4_thisId;
  uint8_T c4_y;
  c4_thisId.fIdentifier = (const char_T *)c4_identifier;
  c4_thisId.fParent = NULL;
  c4_thisId.bParentIsCell = false;
  c4_y = c4_d_emlrt_marshallIn(chartInstance, sf_mex_dup
    (c4_b_is_active_c4_lab6_OnlineClassifier), &c4_thisId);
  sf_mex_destroy(&c4_b_is_active_c4_lab6_OnlineClassifier);
  return c4_y;
}

static uint8_T c4_d_emlrt_marshallIn(SFc4_lab6_OnlineClassifierInstanceStruct
  *chartInstance, const mxArray *c4_u, const emlrtMsgIdentifier *c4_parentId)
{
  uint8_T c4_b_u;
  uint8_T c4_y;
  (void)chartInstance;
  sf_mex_import(c4_parentId, sf_mex_dup(c4_u), &c4_b_u, 1, 3, 0U, 0, 0U, 0);
  c4_y = c4_b_u;
  sf_mex_destroy(&c4_u);
  return c4_y;
}

static void c4_chart_data_browse_helper(SFc4_lab6_OnlineClassifierInstanceStruct
  *chartInstance, int32_T c4_ssIdNumber, const mxArray **c4_mxData, uint8_T
  *c4_isValueTooBig)
{
  *c4_mxData = NULL;
  *c4_mxData = NULL;
  *c4_isValueTooBig = 0U;
  switch (c4_ssIdNumber) {
   case 4U:
    *c4_isValueTooBig = 1U;
    break;

   case 5U:
    sf_mex_assign(c4_mxData, sf_mex_create("mxData", *chartInstance->c4_M, 0, 0U,
      1U, 0U, 1, 7), false);
    break;
  }
}

static const mxArray *c4_HuInvariantMoments
  (SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance, const emlrtStack
   *c4_sp, const mxArray *c4_input0)
{
  const mxArray *c4_m = NULL;
  (void)chartInstance;
  c4_m = NULL;
  sf_mex_assign(&c4_m, sf_mex_call(c4_sp, NULL, "HuInvariantMoments", 1U, 1U, 14,
    sf_mex_dup(c4_input0)), false);
  sf_mex_destroy(&c4_input0);
  return c4_m;
}

static void init_dsm_address_info(SFc4_lab6_OnlineClassifierInstanceStruct
  *chartInstance)
{
  (void)chartInstance;
}

static void init_simulink_io_address(SFc4_lab6_OnlineClassifierInstanceStruct
  *chartInstance)
{
  chartInstance->c4_covrtInstance = (CovrtStateflowInstance *)
    sfrtGetCovrtInstance(chartInstance->S);
  chartInstance->c4_fEmlrtCtx = (void *)sfrtGetEmlrtCtx(chartInstance->S);
  chartInstance->c4_img = (real_T (*)[76800])ssGetInputPortSignal_wrapper
    (chartInstance->S, 0);
  chartInstance->c4_M = (real_T (*)[7])ssGetOutputPortSignal_wrapper
    (chartInstance->S, 1);
}

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* SFunction Glue Code */
void sf_c4_lab6_OnlineClassifier_get_check_sum(mxArray *plhs[])
{
  ((real_T *)mxGetPr((plhs[0])))[0] = (real_T)(1079697637U);
  ((real_T *)mxGetPr((plhs[0])))[1] = (real_T)(2311420938U);
  ((real_T *)mxGetPr((plhs[0])))[2] = (real_T)(2912200292U);
  ((real_T *)mxGetPr((plhs[0])))[3] = (real_T)(584430493U);
}

mxArray *sf_c4_lab6_OnlineClassifier_third_party_uses_info(void)
{
  mxArray * mxcell3p = mxCreateCellMatrix(1,2);
  mxSetCell(mxcell3p, 0, mxCreateString(
             "images.internal.coder.buildable.Grayto8Buildable"));
  mxSetCell(mxcell3p, 1, mxCreateString(
             "images.internal.coder.buildable.GetnumcoresBuildable"));
  return(mxcell3p);
}

mxArray *sf_c4_lab6_OnlineClassifier_jit_fallback_info(void)
{
  const char *infoFields[] = { "fallbackType", "fallbackReason",
    "hiddenFallbackType", "hiddenFallbackReason", "incompatibleSymbol" };

  mxArray *mxInfo = mxCreateStructMatrix(1, 1, 5, infoFields);
  mxArray *fallbackType = mxCreateString("late");
  mxArray *fallbackReason = mxCreateString("ir_function_calls");
  mxArray *hiddenFallbackType = mxCreateString("");
  mxArray *hiddenFallbackReason = mxCreateString("");
  mxArray *incompatibleSymbol = mxCreateString("grayto8_real64");
  mxSetField(mxInfo, 0, infoFields[0], fallbackType);
  mxSetField(mxInfo, 0, infoFields[1], fallbackReason);
  mxSetField(mxInfo, 0, infoFields[2], hiddenFallbackType);
  mxSetField(mxInfo, 0, infoFields[3], hiddenFallbackReason);
  mxSetField(mxInfo, 0, infoFields[4], incompatibleSymbol);
  return mxInfo;
}

mxArray *sf_c4_lab6_OnlineClassifier_updateBuildInfo_args_info(void)
{
  mxArray *mxBIArgs = mxCreateCellMatrix(1,0);
  return mxBIArgs;
}

static const mxArray *sf_get_sim_state_info_c4_lab6_OnlineClassifier(void)
{
  const char *infoFields[] = { "chartChecksum", "varInfo" };

  mxArray *mxInfo = mxCreateStructMatrix(1, 1, 2, infoFields);
  mxArray *mxVarInfo = sf_mex_decode(
    "eNpjYPT0ZQACPhDBxMDABqQ4IEwwYIXyGaFijHBxFri4AhCXVBakgsSLi5I9U4B0XmIumJ9YWuG"
    "Zl5YPNt+CAWE+GxbzGZHM54SKQ8AHe8r0iziA9Bsg6WchoF8AyPKFhQuUJt9+BQfK9EPsjyDgfi"
    "UU90P4mcXxicklmWWp8ckm8TmJSWbx/nk5mXmpzjmJxcWZaZmpRQjzQQAAMdwb6w=="
    );
  mxArray *mxChecksum = mxCreateDoubleMatrix(1, 4, mxREAL);
  sf_c4_lab6_OnlineClassifier_get_check_sum(&mxChecksum);
  mxSetField(mxInfo, 0, infoFields[0], mxChecksum);
  mxSetField(mxInfo, 0, infoFields[1], mxVarInfo);
  return mxInfo;
}

static const char* sf_get_instance_specialization(void)
{
  return "shqQnBRNK3rV3vWPb9nYHpC";
}

static void sf_opaque_initialize_c4_lab6_OnlineClassifier(void *chartInstanceVar)
{
  initialize_params_c4_lab6_OnlineClassifier
    ((SFc4_lab6_OnlineClassifierInstanceStruct*) chartInstanceVar);
  initialize_c4_lab6_OnlineClassifier((SFc4_lab6_OnlineClassifierInstanceStruct*)
    chartInstanceVar);
}

static void sf_opaque_enable_c4_lab6_OnlineClassifier(void *chartInstanceVar)
{
  enable_c4_lab6_OnlineClassifier((SFc4_lab6_OnlineClassifierInstanceStruct*)
    chartInstanceVar);
}

static void sf_opaque_disable_c4_lab6_OnlineClassifier(void *chartInstanceVar)
{
  disable_c4_lab6_OnlineClassifier((SFc4_lab6_OnlineClassifierInstanceStruct*)
    chartInstanceVar);
}

static void sf_opaque_gateway_c4_lab6_OnlineClassifier(void *chartInstanceVar)
{
  sf_gateway_c4_lab6_OnlineClassifier((SFc4_lab6_OnlineClassifierInstanceStruct*)
    chartInstanceVar);
}

static const mxArray* sf_opaque_get_sim_state_c4_lab6_OnlineClassifier(SimStruct*
  S)
{
  return get_sim_state_c4_lab6_OnlineClassifier
    ((SFc4_lab6_OnlineClassifierInstanceStruct *)sf_get_chart_instance_ptr(S));/* raw sim ctx */
}

static void sf_opaque_set_sim_state_c4_lab6_OnlineClassifier(SimStruct* S, const
  mxArray *st)
{
  set_sim_state_c4_lab6_OnlineClassifier
    ((SFc4_lab6_OnlineClassifierInstanceStruct*)sf_get_chart_instance_ptr(S), st);
}

static void sf_opaque_cleanup_runtime_resources_c4_lab6_OnlineClassifier(void
  *chartInstanceVar)
{
  if (chartInstanceVar!=NULL) {
    SimStruct *S = ((SFc4_lab6_OnlineClassifierInstanceStruct*) chartInstanceVar)
      ->S;
    if (sim_mode_is_rtw_gen(S) || sim_mode_is_external(S)) {
      sf_clear_rtw_identifier(S);
      unload_lab6_OnlineClassifier_optimization_info();
    }

    mdl_cleanup_runtime_resources_c4_lab6_OnlineClassifier
      ((SFc4_lab6_OnlineClassifierInstanceStruct*) chartInstanceVar);
    utFree(chartInstanceVar);
    if (ssGetUserData(S)!= NULL) {
      sf_free_ChartRunTimeInfo(S);
    }

    ssSetUserData(S,NULL);
  }
}

static void sf_opaque_mdl_start_c4_lab6_OnlineClassifier(void *chartInstanceVar)
{
  mdl_start_c4_lab6_OnlineClassifier((SFc4_lab6_OnlineClassifierInstanceStruct*)
    chartInstanceVar);
  if (chartInstanceVar) {
    sf_reset_warnings_ChartRunTimeInfo
      (((SFc4_lab6_OnlineClassifierInstanceStruct*)chartInstanceVar)->S);
  }
}

static void sf_opaque_mdl_terminate_c4_lab6_OnlineClassifier(void
  *chartInstanceVar)
{
  mdl_terminate_c4_lab6_OnlineClassifier
    ((SFc4_lab6_OnlineClassifierInstanceStruct*) chartInstanceVar);
}

extern unsigned int sf_machine_global_initializer_called(void);
static void mdlProcessParameters_c4_lab6_OnlineClassifier(SimStruct *S)
{
  int i;
  for (i=0;i<ssGetNumRunTimeParams(S);i++) {
    if (ssGetSFcnParamTunable(S,i)) {
      ssUpdateDlgParamAsRunTimeParam(S,i);
    }
  }

  sf_warn_if_symbolic_dimension_param_changed(S);
  if (sf_machine_global_initializer_called()) {
    initialize_params_c4_lab6_OnlineClassifier
      ((SFc4_lab6_OnlineClassifierInstanceStruct*)sf_get_chart_instance_ptr(S));
    initSubchartIOPointersc4_lab6_OnlineClassifier
      ((SFc4_lab6_OnlineClassifierInstanceStruct*)sf_get_chart_instance_ptr(S));
  }
}

const char* sf_c4_lab6_OnlineClassifier_get_post_codegen_info(void)
{
  int i;
  const char* encStrCodegen [22] = {
    "eNrtWE+P20QUnw3LiopS7QGpIFWi6gkOSNAFBBIqu3ESGrHphjq7BS6rif0SjzIee+dPskF8CQ5",
    "I8C24cOKLcOTOhSNH3thOGnnTxJOIpUVYcpyx/Zvfe2/evzHZaXcIHrfw/PFNQvbw+gqeNZIfLx",
    "fjnYUzv79LPi3G371KSJCEMAThm8GAXRK3Q5i4SyWNFXE/BI3hMaiEG80S0RaDpDqWiQFIEAFOk",
    "CZSO/EqFhvOxKhlRGCZ1ZOIBZEfJYaHdZyQhieCT5/FmxrdRcYGkxDoFkCoI5mYYdTidLjaClJP",
    "vAiCkTKxs60UaN+kVlXVMVyzlEPzEoK2UJqiFdQafX1NNXj60s3IVl/lz9BJnHJGRXVbR1T5kKJ",
    "3aDhNQ/w9MRqtVwkbRFTqOkR0DOqYjTL2REAldqbw7T4TVCeSUd6MuWdnq6hvl6OOHQwJ7rpGqG",
    "9dAh2lCRPaMSD8Ftq5KWifQwP6ZujI68OFsdFwxmAC0m19B14yBkmHcCLcZM7WqHmZOeU8lipiN",
    "YvhjMqjAH1XQeiWNzDolE/RHaGH0zhhITNxW/UkG6NvuOa6tg3/jXKdiXPvVxthM97mGJz9as7b",
    "CoRHOVdu2F6SHsMYeMbfoJpugM35HcBKsbCXoHfYbOOYsYxgGAkF1ktEyKp75biEygrbIyxSFeA",
    "stmEAIZp5Lvp8onVxZJROYg9TTuP4uCLfVWxbaJADGkDlGiMpU4ACZ37lyBsyZQMJ0WglnWlZeY",
    "Y8BjeCEjUwojFJ5Aht7FrMntrKRoIbGsIhJmYNWZJronefUW4qyhyrIcYPusepwizrxotYGz8bg",
    "QMaRBDaysk4dDDP4gRVl1jZkn+E2o6ZnjZABZKlVSPJYELHomut1JumcCpGIpmIlkxiv+i8VvgV",
    "AGYNKgUTwzqWcDltofDVpJZw0cuyu2uTY+1MNad96xufg8BqaHW1XQMNMKqaAltkFGgbrM++xSZ",
    "GKKY0FuppXurzumf794fkaf++u6R/f2Ohf98vxsEH58j70Tl2q0yAxykmzgEDaed7b2G+mxX2Az",
    "M5VuHIFRyZ42bXtxfwO0t4ycK1zHejtlrOGv7bKXCHC7jXSjy7JdxeYbN4dPuP5q8v/fTDO7/8f",
    "uf7B942/D/X3PZbt4rxnVnfNM/S4yuJrIo/3C75gx2r6OJLUX/86IsDeXYwftLtfyK+fph6+fqs",
    "kbdWknd2/67t1TCIs5wgg3ZY7NvsmJp8P2Hn/3hB3r019rix4E+E/PnZdvjXD8vruLsGv4//OiW",
    "/3Zz/7uF2+Jz/qzXy3yut972sdz+nNkPD+bMywdX43NTfXXHkmnEvipz/2+Wf169KvbtuHLlm3L",
    "b6udbxF/39VfWDlN7ff471WJXvXfq5502v34hbv/VWMX4w/57gRYyHS3Y0xWPcdAyWPf2P+Pdfj",
    "vab9ZdNa7/iw/M3B0eC8iluYfItYnG7K+33w/kjCVQt3yf+G/WELNkvLOuvbpbi244nTITJRL37",
    "/v0P729Tn/4GoukdkA==",
    ""
  };

  static char newstr [1521] = "";
  newstr[0] = '\0';
  for (i = 0; i < 22; i++) {
    strcat(newstr, encStrCodegen[i]);
  }

  return newstr;
}

static void mdlSetWorkWidths_c4_lab6_OnlineClassifier(SimStruct *S)
{
  const char* newstr = sf_c4_lab6_OnlineClassifier_get_post_codegen_info();
  sf_set_work_widths(S, newstr);
  ssSetChecksum0(S,(3944180589U));
  ssSetChecksum1(S,(2567158597U));
  ssSetChecksum2(S,(3769969045U));
  ssSetChecksum3(S,(1128173852U));
}

static void mdlRTW_c4_lab6_OnlineClassifier(SimStruct *S)
{
  if (sim_mode_is_rtw_gen(S)) {
    ssWriteRTWStrParam(S, "StateflowChartType", "Embedded MATLAB");
  }
}

static void mdlSetupRuntimeResources_c4_lab6_OnlineClassifier(SimStruct *S)
{
  SFc4_lab6_OnlineClassifierInstanceStruct *chartInstance;
  chartInstance = (SFc4_lab6_OnlineClassifierInstanceStruct *)utMalloc(sizeof
    (SFc4_lab6_OnlineClassifierInstanceStruct));
  if (chartInstance==NULL) {
    sf_mex_error_message("Could not allocate memory for chart instance.");
  }

  memset(chartInstance, 0, sizeof(SFc4_lab6_OnlineClassifierInstanceStruct));
  chartInstance->chartInfo.chartInstance = chartInstance;
  chartInstance->chartInfo.isEMLChart = 1;
  chartInstance->chartInfo.chartInitialized = 0;
  chartInstance->chartInfo.sFunctionGateway =
    sf_opaque_gateway_c4_lab6_OnlineClassifier;
  chartInstance->chartInfo.initializeChart =
    sf_opaque_initialize_c4_lab6_OnlineClassifier;
  chartInstance->chartInfo.mdlStart =
    sf_opaque_mdl_start_c4_lab6_OnlineClassifier;
  chartInstance->chartInfo.mdlTerminate =
    sf_opaque_mdl_terminate_c4_lab6_OnlineClassifier;
  chartInstance->chartInfo.mdlCleanupRuntimeResources =
    sf_opaque_cleanup_runtime_resources_c4_lab6_OnlineClassifier;
  chartInstance->chartInfo.enableChart =
    sf_opaque_enable_c4_lab6_OnlineClassifier;
  chartInstance->chartInfo.disableChart =
    sf_opaque_disable_c4_lab6_OnlineClassifier;
  chartInstance->chartInfo.getSimState =
    sf_opaque_get_sim_state_c4_lab6_OnlineClassifier;
  chartInstance->chartInfo.setSimState =
    sf_opaque_set_sim_state_c4_lab6_OnlineClassifier;
  chartInstance->chartInfo.getSimStateInfo =
    sf_get_sim_state_info_c4_lab6_OnlineClassifier;
  chartInstance->chartInfo.zeroCrossings = NULL;
  chartInstance->chartInfo.outputs = NULL;
  chartInstance->chartInfo.derivatives = NULL;
  chartInstance->chartInfo.mdlRTW = mdlRTW_c4_lab6_OnlineClassifier;
  chartInstance->chartInfo.mdlSetWorkWidths =
    mdlSetWorkWidths_c4_lab6_OnlineClassifier;
  chartInstance->chartInfo.extModeExec = NULL;
  chartInstance->chartInfo.restoreLastMajorStepConfiguration = NULL;
  chartInstance->chartInfo.restoreBeforeLastMajorStepConfiguration = NULL;
  chartInstance->chartInfo.storeCurrentConfiguration = NULL;
  chartInstance->chartInfo.callAtomicSubchartUserFcn = NULL;
  chartInstance->chartInfo.callAtomicSubchartAutoFcn = NULL;
  chartInstance->chartInfo.callAtomicSubchartEventFcn = NULL;
  chartInstance->S = S;
  chartInstance->chartInfo.dispatchToExportedFcn = NULL;
  sf_init_ChartRunTimeInfo(S, &(chartInstance->chartInfo), false, 0,
    chartInstance->c4_JITStateAnimation,
    chartInstance->c4_JITTransitionAnimation);
  init_dsm_address_info(chartInstance);
  init_simulink_io_address(chartInstance);
  if (!sim_mode_is_rtw_gen(S)) {
  }

  mdl_setup_runtime_resources_c4_lab6_OnlineClassifier(chartInstance);
}

void c4_lab6_OnlineClassifier_method_dispatcher(SimStruct *S, int_T method, void
  *data)
{
  switch (method) {
   case SS_CALL_MDL_SETUP_RUNTIME_RESOURCES:
    mdlSetupRuntimeResources_c4_lab6_OnlineClassifier(S);
    break;

   case SS_CALL_MDL_SET_WORK_WIDTHS:
    mdlSetWorkWidths_c4_lab6_OnlineClassifier(S);
    break;

   case SS_CALL_MDL_PROCESS_PARAMETERS:
    mdlProcessParameters_c4_lab6_OnlineClassifier(S);
    break;

   default:
    /* Unhandled method */
    sf_mex_error_message("Stateflow Internal Error:\n"
                         "Error calling c4_lab6_OnlineClassifier_method_dispatcher.\n"
                         "Can't handle method %d.\n", method);
    break;
  }
}
