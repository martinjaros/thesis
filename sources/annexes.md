\appendix

# Threads example {#appendixa}

In this example two threads share standard input and output,
access is restricted by *mutexes* so only one thread may use the shared resource at any time.

~~~{.c .numberLines}
#include <stdio.h>
#include <pthread.h>

void *worker1(void *arg)
{
    pthread_mutex_t *mutex = (pthread_mutex_t*)arg;
    static char buffer[64];

    // Lock mutex to restrict access to stdin and stdout
    pthread_mutex_lock(mutex);
    printf("This is worker 1, enter something: ");
    scanf("%64s", buffer);
    pthread_mutex_unlock(mutex);

    return (void*)buffer;
}

void *worker2(void *arg)
{
    pthread_mutex_t *mutex = (pthread_mutex_t*)arg;
    static char buffer[64];

    // Lock mutex to restrict access to stdin and stdout
    pthread_mutex_lock(mutex);
    printf("This is worker 2, enter something: ");
    scanf("%64s", buffer);
    pthread_mutex_unlock(mutex);

    return (void*)buffer;
}

int main()
{
    pthread_mutex_t mutex;
    pthread_t thread1, thread2;
    char *retval1, *retval2;

    // Initialize two threads with shared mutex, use default parameters
    pthread_mutex_init(&mutex, NULL);
    pthread_create(&thread1, NULL, worker1, (void*)&mutex);
    pthread_create(&thread2, NULL, worker2, (void*)&mutex);

    // Wait for both threads to finish and display results
    pthread_join(thread1, (void**)&retval1);
    pthread_join(thread2, (void**)&retval2);
    printf("Thread 1 returned with `%s`.\n", retval1);
    printf("Thread 2 returned with `%s`.\n", retval2);

    pthread_mutex_destroy(&mutex);
    return 0;
}
~~~

# Video capture example {#appendixb}

In this example video device is configured to capture frames using memory mapping.
These frames are dumped to standard output, instead of further processing.

~~~{.c .numberLines}
#include <fcntl.h>
#include <unistd.h>
#include <poll.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <linux/videodev2.h>

int main()
{
    // Open device
    int fd = open("/dev/video0", O_RDWR | O_NONBLOCK);

    // Set video format
    struct v4l2_format format =
    {
        .type = V4L2_BUF_TYPE_VIDEO_CAPTURE,
        .fmt =
        {
            .pix =
            {
                .width = 320,
                .height = 240,
                .pixelformat = V4L2_PIX_FMT_RGB32,
                .field = V4L2_FIELD_NONE,
                .colorspace = V4L2_COLORSPACE_SMPTE170M,
            },
        },
    };
    ioctl(fd, VIDIOC_S_FMT, &format);

    // Request buffers
    struct v4l2_requestbuffers requestbuffers =
    {
        .type = V4L2_BUF_TYPE_VIDEO_CAPTURE,
        .memory = V4L2_MEMORY_MMAP,
        .count = 4,
    };
    ioctl(fd, VIDIOC_REQBUFS, &requestbuffers);
    void *pbuffers[requestbuffers.count];

    // Map and enqueue buffers
    int i;
    for(i = 0; i < requestbuffers.count; i++)
    {
        struct v4l2_buffer buffer = 
        {
            .type = V4L2_BUF_TYPE_VIDEO_CAPTURE,
            .memory = V4L2_MEMORY_MMAP,
            .index = i,
        };
        ioctl(fd, VIDIOC_QUERYBUF, &buffer);
        pbuffers[i] = mmap(NULL, buffer.length,
                           PROT_READ | PROT_WRITE, MAP_SHARED,
                           fd, buffer.m.offset);
        ioctl(fd, VIDIOC_QBUF, &buffer);
    }

    // Start stream
    enum v4l2_buf_type buf_type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    ioctl(fd, VIDIOC_STREAMON, &buf_type);

    while(1)
    {
        // Synchronize
        struct pollfd fds = 
        {
            .fd = fd,
            .events = POLLIN
        };
        poll(&fds, 1, -1);

        // Dump buffer to stdout
        struct v4l2_buffer buffer = 
        {
            .type = V4L2_BUF_TYPE_VIDEO_CAPTURE,
            .memory = V4L2_MEMORY_MMAP,
        };
        ioctl(fd, VIDIOC_DQBUF, &buffer);
        write(1, pbuffers[buffer.index], buffer.bytesused);
        ioctl(fd, VIDIOC_QBUF, &buffer);
    }
}
~~~
<!-- -->

# Colorspace conversion example {#appendixc}

In this example RGB to YUV color-space conversion is implemented in fragment shader.
Each input channel has its own texturing unit, texture coordinates are divided by sub-sampling factor 4:2:0.

~~~{.c .numberLines}
uniform sampler2D texY, texU, texV;
varying vec2 texCoord;

void main()
{
    float y = texture2D(texY, texCoord).a * 1.1644 - 0.062745;
    float u = texture2D(texU, texCoord / 2).a - 0.5;
    float v = texture2D(texV, texCoord / 2).a - 0.5;

    gl_FragColor = vec4(
        y + 1.596 * v,
        y - 0.39176 * v - 0.81297 * u,
        y + 2.0172 * u,
        1.0);
}
~~~

