//
//  main.m
//  iVerb
//
//  Created by Max on 9/11/10.
//  Copyright Lisacintosh 2010. All rights reserved.
//

#import "AppDelegate_Phone.h"
#import "AppDelegate_Pad.h"

int main(int argc, char *argv[]) {
    
    @autoreleasepool {
        NSString * className = NSStringFromClass((TARGET_IS_IPAD()) ? AppDelegate_Pad.class : AppDelegate_Phone.class);
        return UIApplicationMain(argc, argv, nil, className);
    }
}
