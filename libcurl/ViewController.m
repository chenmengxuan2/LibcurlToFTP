//
//  ViewController.m
//  libcurl
//
//  Created by Mengxuan Chen on 2017/12/27.
//  Copyright © 2017年 Mengxuan Chen. All rights reserved.
//

#import "ViewController.h"
#import <curl/curl.h>
#include <sys/stat.h>
@interface ViewController ()

@end

@implementation ViewController
{
    
    CURL *currentCurl;
}
struct FtpFile   //定义一个结构为了传递给my_fwrite函数.可用curl_easy_setopt的CURLOPT_WRITEDATA选项传递
{
    char *filename;
    FILE *stream;
    
};


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    currentCurl =  curl_easy_init();
//    curl_easy_setopt(currentCurl,CURLOPT_PASSWORD);

    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *path2 = [path stringByAppendingString:@"/12345.3gp"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        void *p = (__bridge void *)self;
        download(p,currentCurl,  "ftp://169.254.51.31//Users/mengxuanchen/Desktop/2017_01_01_08_04_05.3gp",[path2 cStringUsingEncoding:NSUTF8StringEncoding], 5, 3);

        curl_easy_cleanup(currentCurl);
    });
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
//        void *p = (__bridge void *)self;
//        download(p,currentCurl,  "ftp://169.254.155.42//Users/mengxuanchen/Desktop/2017_10_09_11_07_06.3gp",[path2 cStringUsingEncoding:NSUTF8StringEncoding], 5, 3);
//        curl_easy_cleanup(currentCurl);
//    });
//    [self getListFileName];
}

- (IBAction)startOtherTask:(id)sender {
    currentCurl =  curl_easy_init();
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *path2 = [path stringByAppendingString:@"/371.3gp"];
    void *p = (__bridge void *)self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        download(p,currentCurl,  "ftp://169.254.51.31//Users/mengxuanchen/Desktop/2017_01_01_08_04_05.3gp",[path2 cStringUsingEncoding:NSUTF8StringEncoding], 5, 3);
         curl_easy_cleanup(currentCurl);
    });
    
}

//获取目录
- (void)getListFileName{
    
    curl_easy_setopt(currentCurl, CURLOPT_URL, "ftp://169.254.51.31//Users/mengxuanchen/Desktop");
    curl_easy_setopt(currentCurl, CURLOPT_USERPWD, "mengxuanchen:123456");
    CURLcode ret = curl_easy_perform(currentCurl);
    if (CURLE_OK != ret) {
        fprintf(stderr, "ERROR: %s", ret);
    }
}
//下载
int download(void *ocObj,CURL *curlhandle, const char * remotepath, const char * localpath, long timeout, long tries)
{
    
    FILE *f;
    curl_off_t local_file_len = -1 ;
    long filesize =0 ;
    CURLcode r = CURLE_GOT_NOTHING;
    struct stat file_info;
    int use_resume = 0;
    //获取本地文件大小信息
    if(stat(localpath, &file_info) == 0)
    {
        local_file_len = file_info.st_size;
        use_resume = 1;
    }
    //追加方式打开文件，实现断点续传
    f = fopen(localpath, "ab+");
    if (f == NULL) {
        perror(NULL);
        return 0;
    }
//    curl_easy_setopt(curlhandle, CURLOPT_FTP_FILEMETHOD, CURLFTPMETHOD_NOCWD);
    curl_easy_setopt(curlhandle, CURLOPT_URL, remotepath);
    curl_easy_setopt(curlhandle, CURLOPT_USERPWD, "mengxuanchen:123456");
    //连接超时设置
    curl_easy_setopt(curlhandle, CURLOPT_CONNECTTIMEOUT, timeout);
    //设置头处理函数
    curl_easy_setopt(curlhandle, CURLOPT_HEADERFUNCTION, getcontentlengthfunc);
    curl_easy_setopt(curlhandle, CURLOPT_HEADERDATA, &filesize);
    // 设置断点续传
    
    curl_easy_setopt(curlhandle, CURLOPT_RESUME_FROM_LARGE, use_resume?local_file_len:0);
    curl_easy_setopt(curlhandle, CURLOPT_WRITEFUNCTION, writefunc);
    curl_easy_setopt(curlhandle, CURLOPT_PROGRESSFUNCTION,my_progress_callback);
    curl_easy_setopt(curlhandle, CURLOPT_PROGRESSDATA, ocObj);
    curl_easy_setopt(curlhandle, CURLOPT_WRITEDATA, f);
    curl_easy_setopt (curlhandle, CURLOPT_NOPROGRESS, 0);
    curl_easy_setopt(curlhandle, CURLOPT_VERBOSE, 1L);
    
    
//    curl_easy_setopt(curlhandle, CURLOPT_DIRLISTONLY,fileListFunc);
    r = curl_easy_perform(curlhandle);
    fclose(f);
    if (r == CURLE_OK)
        return 1;
    else {
        fprintf(stderr, "%s\n", curl_easy_strerror(r));
        return 0;
    }
}

void fileListFunc(){
    
    
}

size_t getcontentlengthfunc(void *ptr, size_t size, size_t nmemb, void *stream)
{
    int r;
    long len = 0;
    /* _snscanf() is Win32 specific */
    //r = _snscanf(ptr, size * nmemb, "Content-Length: %ld\n", &len);
    r = sscanf((const char*)ptr, "Content-Length: %ld\n", &len);
    if (r) /* Microsoft: we don't read the specs */
        *((long *) stream) = len;
    return size * nmemb;
}
/* discard downloaded data */
size_t discardfunc(void *ptr, size_t size, size_t nmemb, void *stream)
{
    return size * nmemb;
}
//write data to upload
size_t writefunc(void *ptr, size_t size, size_t nmemb, void *stream)
{
//    ViewController *view =
    
    FILE * s = stream;
    printf(s ->_extra);
    return fwrite(ptr, size, nmemb, (FILE*)stream);
}
/* read data to upload */
size_t readfunc(void *ptr, size_t size, size_t nmemb, void *stream)
{
    FILE *f = (FILE*)stream;
    size_t n;
    if (ferror(f))
        return CURL_READFUNC_ABORT;
    n = fread(ptr, size, nmemb, f) * size;
    return n;
}

//进度回调
int my_progress_callback(void* ocPtr, double TotalToDownload, double NowDownloaded, double TotalToUpload, double NowUpload)
{
    
    if (ocPtr) {
        id oc = (__bridge id)ocPtr;
    
        //how wide you want the progress bar to be ?
        int totalDot = 80;
        
        double fractionDownloaded = 0.0;
        if(TotalToDownload != 0)
            fractionDownloaded = NowDownloaded / TotalToDownload;//注意0不能为分母
        else
            fractionDownloaded = 0;
        //the full part of progress bar
        int dot = round(fractionDownloaded * totalDot);
        
        //create the progress bar, but control to print
    //    if(dot % 10 == 0){
            printf("total: %0.0f, now: %0.0f\n", TotalToDownload, NowDownloaded);
            int i = 0;
            printf("%3.0f%% [", fractionDownloaded * 100);
            for(; i < dot; i++)
                printf("="); // full part
            for(; i < totalDot; i++)
                printf(" "); // remainder part
            printf("]\n");
            fflush(stdout); //avoid output buffering problems
    //    }
        
        return 0;
    }else {
        return -1;
    }
    
}
int Curl_resolv_timeout(struct connectdata *conn,
                        const char *hostname,
                        int port,
                        struct Curl_dns_entry **entry,
                        long timeoutms){
    
    return 10;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)pauseClick:(id)sender {
    
    curl_easy_pause(currentCurl, CURLPAUSE_ALL);
}

- (IBAction)startDownload:(id)sender {
    
    curl_easy_pause(currentCurl, CURLPAUSE_CONT);
}
@end
