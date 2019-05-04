function f = maxproj_imshowpair(image1, image2, brightness)
    f = imshowpair(brightness*max(image1,[],3), brightness*max(image2,[],3));