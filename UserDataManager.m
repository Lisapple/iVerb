//
//  UserDataManager.m
//  iVerb
//
//  Created by Max on 16/04/2017.
//
//

#import "UserDataManager.h"

#import "ManagedObjectContext.h"
#import "Playlist.h"
#import "Verb.h"
#import "QuizResult.h"
#import "UserDataEvent.h"

#import "Playlist+additions.h"
#import "Verb+additions.h"
#import "NSDate+addition.h"
#import "NSManagedObject+addition.h"

@implementation Playlist (infinitives)

- (NSArray<NSString *> *)infinitives
{
	return [(NSSet *)[self.verbs valueForKey:SelectorName(infinitif)] allObjects] ?: @[];
}

@end

@implementation QuizResult (score)

+ (NSDateFormatter *)keyValueStoreFormatter
{
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = @"dd/MM/yy HH:mm:ss";
	return formatter;
}

- (NSInteger)score
{
	return self.rightResponses.integerValue;
}

- (NSInteger)total
{
	return (self.rightResponses.integerValue + self.wrongResponses.integerValue);
}

@end

static UserDataManager * __defaultManager = nil;

NSString * const KeyValueStoreListsKey = @"lists"; // Value is `KVSLists` type
NSString * const KeyValueStoreBookmarksKey = @"bookmarks"; // Value is `KVSBookmarks` type
NSString * const KeyValueStoreNotesKey = @"notes"; // Value is `KVSNotes` type

/// An array of dictionary with all playlists:
///   `@{ "name": playlist name, "verbs": @[ infinitives ], "quiz": { "16/04/17 12:37:00": "6/8" } }`
typedef DictionaryTy(String, Object) KVSList;
typedef NSArray <KVSList *>			 KVSLists;
/// An array of infinitif for each bookmarked verbs: `@[ infinitif ]`
typedef ArrayTy(String)				 KVSBookmarks;
/// A dictionary with all notes: `@{ verb infinitif : note content }`
typedef DictionaryTy(String, String) KVSNotes;

NSString * const UserDataEventsKey = @"userDataEvents";

@interface UserDataManager ()

/// Non-shared local user defaults; contains notes (`note_[infinitif]`), last selected playlist (`UserDefaultsLastUsedPlaylistKey`) and verb displayed count `UserDefaultsVerbPopularitiesKey`
@property (nonatomic, strong) NSUserDefaults * userDefaults;

/// iCloud store; contains lists, bookmarks and notes
/// @see `KeyValueStoreXXXKey` keys and `KVSXXX` types for more details on format.
@property (nonatomic, strong) NSUbiquitousKeyValueStore * keyValueStore;

/// Local Core Data's managed object context; contains lists, verbs, quotes and quiz results
@property (nonatomic, strong) NSManagedObjectContext * managedObjectContext;

@end

@implementation UserDataManager

+ (instancetype)defaultManager
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__defaultManager = [[UserDataManager alloc] init];
	});
	return __defaultManager;
}

- (instancetype)init
{
	if ((self = [super init])) {
		_userDefaults = [NSUserDefaults standardUserDefaults]; // Synchronization not needed to get it up to date
		_keyValueStore = [NSUbiquitousKeyValueStore defaultStore];
		_managedObjectContext = [ManagedObjectContext sharedContext];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateExternalStore:)
													 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
												   object:nil];
		[self startObservingEventNotifications];
		
		[_keyValueStore synchronize];
	}
	return self;
}

- (NSArray <NSString *> *)eventNotificationNames
{
	return @[ PlaylistDidCreateNotification, PlaylistWillDeleteNotification, PlaylistDidUpdateNameNotification,
			  PlaylistDidAddVerbNotification, PlaylistDidRemoveVerbNotification,
			  VerbDidUpdateNoteNotification, VerbDidRemoveNoteNotification ];
}

- (void)startObservingEventNotifications
{
	for (NSString * name in self.eventNotificationNames)
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveEvent:) name:name object:nil];
}

- (void)stopObservingEventNotifications
{
	for (NSString * name in self.eventNotificationNames)
		[[NSNotificationCenter defaultCenter] removeObserver:self name:name object:nil];
}

- (void)saveEvent:(NSNotification *)notification
{
	Playlist * playlist = ([notification.object isKindOfClass:Playlist.class]) ? notification.object : nil;
	if ([playlist isHistoryPlaylist])
		return ;
	
	UserDataEvent* (^createEventFromNotification)(NSNotification *) = ^UserDataEvent*(NSNotification * notification){
		if /**/ ([notification.name isEqualToString:PlaylistDidCreateNotification]) {
			UDPlaylistEvent * event = [[UDPlaylistCreateEvent alloc] init];
			event.playlistName = playlist.name;
			return event;
		}
		else if ([notification.name isEqualToString:PlaylistWillDeleteNotification]) {
			UDPlaylistEvent * event = [[UDPlaylistDeleteEvent alloc] init];
			event.playlistName = playlist.name;
			return event;
		}
		else if ([notification.name isEqualToString:PlaylistDidUpdateNameNotification]) {
			UDPlaylistRenameEvent * event = [[UDPlaylistRenameEvent alloc] init];
			event.playlistName = playlist.name;
			event.originalName = notification.userInfo[@"oldName"];
			assert(event.originalName);
			return event;
		}
		else if ([notification.name isEqualToString:PlaylistDidAddVerbNotification]) {
			UDPlaylistAddVerbEvent * event = [[UDPlaylistAddVerbEvent alloc] init];
			Verb * const verb = notification.userInfo[@"verb"];
			assert(verb);
			event.infinitif = verb.infinitif;
			event.playlistName = playlist.name;
			return event;
		}
		else if ([notification.name isEqualToString:PlaylistDidRemoveVerbNotification]) {
			UDPlaylistRemoveVerbEvent * event = [[UDPlaylistRemoveVerbEvent alloc] init];
			Verb * const verb = notification.userInfo[@"verb"];
			assert(verb);
			event.infinitif = verb.infinitif;
			event.playlistName = playlist.name;
			return event;
		}
		else if ([notification.name isEqualToString:VerbDidUpdateNoteNotification]) {
			UDVerbAddNoteEvent * event = [[UDVerbAddNoteEvent alloc] init];
			Verb * const verb = notification.object;
			event.infinitif = verb.infinitif;
			event.note = verb.note;
			return event;
		}
		else if ([notification.name isEqualToString:VerbDidRemoveNoteNotification]) {
			UDVerbRemoveNoteEvent * event = [[UDVerbRemoveNoteEvent alloc] init];
			Verb * const verb = notification.object;
			event.infinitif = verb.infinitif;
			return event;
		}
		assert(false);
	};
	UserDataEvent * event = createEventFromNotification(notification);
	NSDebugLog(@"Saving user data event: %@", event);
	
	// Save event to user defaults
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray <NSData *> * eventDatas = ([userDefaults arrayForKey:UserDataEventsKey] ?: @[]).mutableCopy;
	[eventDatas addObject:[NSKeyedArchiver archivedDataWithRootObject:event]];
	[userDefaults setObject:eventDatas forKey:UserDataEventsKey];
}

- (void)updateExternalStore:(NSNotification *)notification
{
	NSNumber * const changeReason = notification.userInfo[NSUbiquitousKeyValueStoreChangeReasonKey];
	if (!changeReason)
		return ;
	
	BOOL hasChanges = ((changeReason.integerValue == NSUbiquitousKeyValueStoreServerChange) ||
					   (changeReason.integerValue == NSUbiquitousKeyValueStoreInitialSyncChange));
	if (hasChanges) {
		NSArray * const changedKeys = notification.userInfo[NSUbiquitousKeyValueStoreChangedKeysKey];
		for (NSString * key in changedKeys) {
			if ([key isEqualToString:KeyValueStoreListsKey]) {
				KVSLists * lists = (KVSLists *)[_keyValueStore arrayForKey:key];
				if (!lists)
					continue;
				
				// Create/delete local playlists
				NSMutableArray <NSString *> * names = [NSMutableArray arrayWithCapacity:lists.count];
				for (KVSList * list in lists) [names addObject:(NSString *)list[@"name"]];
				
				for (Playlist * playlist in [Playlist userPlaylists]) {
					if (![names containsObject:playlist.name]) // Removed playlist
						[_managedObjectContext deleteObject:playlist];
				}
				for (NSString * name in names) {
					if (![Playlist playlistWithName:name]) // New playlist
						[Playlist insertPlaylistWithName:name inManagedObjectContext:_managedObjectContext];
				}
				[_managedObjectContext save:nil];
				
				// Update playlists
				for (KVSList * list in lists) {
					NSString * const name = (NSString *)list[@"name"];
					Playlist * playlist = [Playlist playlistWithName:name];
					assert(playlist);
					
					// Update verbs
					Array(String) infinitives = (Array(String))list[@"verbs"];
					NSArray <Verb *> * updatedVerbs = [Verb verbsWithInfinitives:infinitives];
					playlist.verbs = [NSSet setWithArray:updatedVerbs];
					
					NSMutableSet <QuizResult *> * quizResults = [playlist mutableSetValueForKey:SelectorName(quizResults)];
					
					// Update quiz
					Dictionary(String, String) results = (Dictionary(String, String))list[@"quiz"];
					for (NSString * dateString in results) { // `quiz = @{ @"16/04/2017" : @"6/8" }`
						NSDate * const date = [[QuizResult keyValueStoreFormatter] dateFromString:dateString];
						
						NSString * resultString = results[dateString];
						long score = 0, total = 0;
						if (sscanf([resultString cStringUsingEncoding:NSUTF8StringEncoding], "%ld/%ld", &score, &total) == 2) {
							BOOL existingFound = NO;
							for (QuizResult * result in playlist.quizResults) {
								if ((existingFound |= (ABS([date timeIntervalSinceDate:result.date]) < 5 &&
													   result.score == score && result.total == total) ))
									break;
							}
							// If no matching (i.e. same day, score and total) quiz result, insert the one from iCloud
							if (!existingFound) {
								QuizResult * quizResult = [QuizResult instanciateInContext:_managedObjectContext];
								quizResult.date = date;
								quizResult.rightResponses = @(score);
								quizResult.wrongResponses = @(total - score);
								[quizResults addObject:quizResult];
							}
						}
					}
				}
				[_managedObjectContext save:nil];
			}
			else if ([key isEqualToString:KeyValueStoreBookmarksKey]) {
				KVSBookmarks * bookmarks = (KVSBookmarks *)[_keyValueStore arrayForKey:key];
				if (!bookmarks)
					continue;
				
				// Update bookmarks
				Playlist * playlist = [Playlist bookmarksPlaylist];
				NSMutableSet <Verb *> * verbs = [playlist mutableSetValueForKey:SelectorName(verbs)];
				[verbs removeAllObjects];
				[verbs addObjectsFromArray:[Verb verbsWithInfinitives:bookmarks]];
				[_managedObjectContext save:nil];
			}
			else if ([key isEqualToString:KeyValueStoreNotesKey]) {
				KVSNotes * notes = (KVSNotes *)[_keyValueStore dictionaryForKey:key];
				if (!notes)
					continue;
				
				// Update User Defaults notes
				for (NSString * infinitif in notes) {
					NSString * const key = [NSString stringWithFormat:@"note_%@", infinitif];
					[_userDefaults setObject:notes[infinitif] forKey:key];
				}
			}
		}
		
		// Re-apply events
		[self stopObservingEventNotifications];
		
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSMutableArray <UserDataEvent *> * events = [NSMutableArray arrayWithCapacity:10];
		for (NSData * eventData in [userDefaults arrayForKey:UserDataEventsKey]) {
			UserDataEvent * const event = [NSKeyedUnarchiver unarchiveObjectWithData:eventData];
			if (event) [events addObject:event];
		}
		[events sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:SelectorName(timestamp)
																	  ascending:YES] ]];
		
		for (UserDataEvent * anEvent in events) {
			if (anEvent.timestamp.timeIntervalSinceNow < -2 * 7 * 24 * 60 * 60) // Ignore if older than 2 weeks
				continue;
			
			if /**/ ([anEvent isKindOfClass:UDPlaylistCreateEvent.class]) {
				UDPlaylistEvent * event = (UDPlaylistCreateEvent *)anEvent;
				NSString * const name = event.playlistName;
				Playlist * const playlist = [Playlist playlistWithName:name];
				if (!playlist && name)
					[Playlist insertPlaylistWithName:name
							  inManagedObjectContext:_managedObjectContext];
			}
			else if ([anEvent isKindOfClass:UDPlaylistDeleteEvent.class]) {
				UDPlaylistEvent * event = (UDPlaylistDeleteEvent *)anEvent;
				Playlist * const playlist = [Playlist playlistWithName:event.playlistName];
				if (playlist)
					[_managedObjectContext deleteObject:playlist];
			}
			else if ([anEvent isKindOfClass:UDPlaylistRenameEvent.class]) {
				UDPlaylistRenameEvent * event = (UDPlaylistRenameEvent *)anEvent;
				Playlist * const playlist = [Playlist playlistWithName:event.originalName];
				playlist.name = event.playlistName;
			}
			else if ([anEvent isKindOfClass:UDPlaylistAddVerbEvent.class]) {
				UDPlaylistAddVerbEvent * event = (UDPlaylistAddVerbEvent *)anEvent;
				Playlist * const playlist = [Playlist playlistWithName:event.playlistName];
				[playlist addVerb:[Verb verbWithInfinitif:event.infinitif]];
			}
			else if ([anEvent isKindOfClass:UDPlaylistRemoveVerbEvent.class]) {
				UDPlaylistRemoveVerbEvent * event = (UDPlaylistRemoveVerbEvent *)anEvent;
				Playlist * const playlist = [Playlist playlistWithName:event.playlistName];
				[playlist removeVerb:[Verb verbWithInfinitif:event.infinitif]];
			}
			else if ([anEvent isKindOfClass:UDVerbAddNoteEvent.class]) {
				UDVerbAddNoteEvent * event = (UDVerbAddNoteEvent *)anEvent;
				[Verb verbWithInfinitif:event.infinitif].note = event.note;
			}
			else if ([anEvent isKindOfClass:UDVerbRemoveNoteEvent.class]) {
				UDVerbRemoveNoteEvent * event = (UDVerbRemoveNoteEvent *)anEvent;
				[Verb verbWithInfinitif:event.infinitif].note = nil;
			}
		}
		if ([_managedObjectContext save:nil])
			[userDefaults removeObjectForKey:UserDataEventsKey];
		
		[self startObservingEventNotifications];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PlaylistDidUpdatedNotification object:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:ResultsDidChangeNotification object:nil];
	}
}

- (BOOL)synchronize
{
	NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(Verb.class)];
	request.predicate = [NSPredicate predicateWithValue:YES];
	NSArray <Verb *> * allVerbs = (NSArray *)[_managedObjectContext executeFetchRequest:request error:nil];
	
	// Notes
	MDictionary(String, String) notes = [NSMutableDictionary dictionaryWithCapacity:100];
	for (NSString * infinitif in [allVerbs valueForKey:SelectorName(infinitif)]) {
		NSString * const key = [NSString stringWithFormat:@"note_%@", infinitif];
		NSString * note = [_userDefaults stringForKey:key];
		if (note)
			notes[infinitif] = note;
	}
	[_keyValueStore setDictionary:notes forKey:KeyValueStoreNotesKey];
	
	// Bookmarks
	Array(String) bookmarks = [Playlist bookmarksPlaylist].infinitives;
	[_keyValueStore setArray:bookmarks forKey:KeyValueStoreBookmarksKey];
	
	// Playlists
	NSMutableArray <Dictionary(String, Object)> * lists = [NSMutableArray arrayWithCapacity:5];
	for (Playlist * playlist in [Playlist userPlaylists]) {
		MDictionary(String, String) results = [NSMutableDictionary dictionaryWithCapacity:playlist.quizResults.count];
		for (QuizResult * result in playlist.quizResults) {
			NSString * const key = [[QuizResult keyValueStoreFormatter] stringFromDate:result.date];
			results[key] = [NSString stringWithFormat:@"%ld/%ld", (long)result.score, (long)result.total];
		}
		[lists addObject:@{ @"name" : playlist.name,
							@"verbs": playlist.infinitives,
							@"quiz" : results }];
	}
	[_keyValueStore setArray:lists forKey:KeyValueStoreListsKey];
	
	return [_keyValueStore synchronize];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
