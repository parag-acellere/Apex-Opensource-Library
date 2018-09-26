# Salesforce Developer Toolkit
## Introduction


## [Collections](https://github.com/amorek/sfdc-toolkit)
This utility class contains methods for the most common operations on Salesforce collections:
- mapping by field
- groupping by field
- filtering
- finding
- sorting
- wrapping into wrapper classes
- filling lists with clones.
- others 

All methods in this class can be used as a wrapper on list instance and chained ala lambda:
```apex
        Map<Boolean, List<OpportunityWrapper2>> actual = (Map<Boolean, List<OpportunityWrapper2>>)
                new Collection(opportunities)
                        .filter(Opportunity.CreatedDate, '>=', Date.today().addDays(-3))
                        .filter(new CollectionFilters.ByFieldValues(Opportunity.StageName,'IN', new Set<Object>{'Analysis','Presales'}))
                        .forEach(new AppendIndexToOpportunityNameWorker())
                        .wrap(OpportunityWrapper2.class)
                        .groupBy(new WrapperByOpenActivityMapper());
```
or as static methods
```apex
    List<Account> accounts = Collection.filter(accounts, new TriggeredAccountsFilter());
    
    List<Account> relatedToParentIds = Collection.filter(accounts, new CollectionFilters.RelatedTo(parentAccounts, Account.ParentId));
```
Many of these methods are based on Javascript Array methods.

#### Methods:




##### getUniqueValues()
Return Set of values gathered from given collection items.
Values are gathered by implementation of KeyMapper, which extracts value from entity, but it's also possible
to use shorthand methods for SObjects, which call in-built implementations.

###### Methods:
```apex
Object getUniqueValues(SObjectField field)
Object getUniqueValues(Type valueType, String field)
Object getUniqueValues(KeyMapper keyMapper)
Set<Object> getUniqueValues(List<SObjectField> fields)

static Object getUniqueValues(List<SObject> records, SObjectField field) 
static Object getUniqueValues(Type valueType, List<SObject> records, String field) 
static Object getUniqueValues(List<Object> records, KeyMapper keyMapper) 
static Set<Object> getUniqueValues(List<SObject> records, List<SObjectField> fields) 
```


###### Examples
```apex
/*Static through SObject field*/
Set<String> accountNames = (Set<String>) Collection.getUniqueValues(accounts, Account.Name);

/*Through instance*/
Set<Datetime> accountCreatedDates = (Set<Datetime>) new Collection(accounts).getUniqueValues(Account.Datetime);

/*Through String field. Values type has to be provided.*/
Set<Id> parentAccountIds = (Set<Id>) Collection.getUniqueValues(Id.class, accounts, 'ParentId');

/*From non-SObject entities through KeyMapper interface implementation*/
Set<Id> parentAccountIds = (Set<Id>) new Collection(accountWrappers).getUniqueValues(new GetAccountWrapperIds());

/*From many fields*/
Set<Id> parentAccountIds = (Set<Id>) new Collection(accounts).getUniqueValues(new Set<SObjectField>{Account.ParentId, Account.Parent__c});

```




##### mapBy
Map collection items using: 
- KeyMapper implementation (Map's key is generated by KeyMapper, while collection item is the value)
- Mapper implementation (Both map's key and value are generated by Mapper)
- Shorthand methods which use in-built implementations:
    - Map by SObject field
    

###### Methods:
```apex
Object mapBy(SObjectField field)
Object mapBy(Type keyType, String field)
Object mapBy(KeyMapper mapper)
Object mapBy(Mapper mapper)

static Object mapBy(List<SObject> records, SObjectField field)
static Object mapBy(Type keyType, List<SObject> records, String field)
static Object mapBy(List<Object> items, KeyMapper mapper)
static Object mapBy(List<Object> items, Mapper mapper)
```


###### Inbuilt implementations:
```apex
CollectionMappers.ByField - Maps SObject by given field
CollectionMappers.ByFieldPair - Maps SObject by pair of fields
```

###### Interfaces
```
    /**
     * KeyMapper implementations determine Map's key for given object and key's type.
     */
    public interface KeyMapper {
        Object key(Object item);
        Type keyType();
    }

    /**
     * Mapper implementations determine Map's key and value for given object and types of key and value.
     */
    public interface Mapper {
        Type keyType();
        Type valueType();
        Object key(Object item);
        Object value(Object item);
    }
```

###### Examples
```apex
/*Shorthand method to maps Accounts by Name field*/
Map<String, Account> accountByNames = (Map<String, Account>) Collection.mapBy(accounts, Account.Name);

/*Shorthand method to maps Accounts by Name field (given as string)*/
Map<String, Account> accountByNames = (Map<String, Account>) new Collection(accounts).mapBy(String.class, 'Name');

/** Maps by custom Mapper implementation, which generates both map's key and value*/
Map<Id, AccountWrapper> accountWrappersByParent = (Map<Id, AccountWrapper>) Collection.mapBy(accounts, new AccountWrapperByIdMapper());

private class AccountWrapperByIdMapper implements Mapper{
            public Type keyType() {
                return Id.class
            }
            public Type valueType() {
                return AccountWrapper.class;
            }
    
            public Object key(Object item) {
                return ((Account) item).Id;
            }
    
            public Object value(Object item) {
                return new AccountWrapper((Account) item);
            }
}
```




##### groupBy
Groups collection items by given Mapper/KeyMapper implementation to Map<Key, List<Value>>, where Key is produced
by Mapper and Map's value is list of collection items with the same map key.
This method can be used with:
- KeyMapper implementation (Map's key is generated by KeyMapper, while collection item is the value)
- Mapper implementation (Both map's key and value are generated by Mapper)
- Shorthand methods which use in-built implementations:
    - Map by SObject field

    
###### Methods:
```apex
Object groupBy(SObjectField field)
Object groupBy(Type keyType, String field)
Object groupBy(KeyMapper keyMapper)
Object groupBy(Mapper mapper)

static Object groupBy(List<SObject> records, SObjectField field) 
static Object groupBy(Type keyType, List<SObject> records, String field) 
static Object groupBy(List<Object> items, KeyMapper keyMapper) 
static Object groupBy(List<Object> items, Mapper mapper) 
```
    
###### Inbuilt implementations:
```apex
CollectionMappers.ByField - Maps SObject by given field
CollectionMappers.ByFieldPair - Maps SObject by pair of fields
```

###### Examples
```apex
//Shorthand method using SObject field
Map<String, List<Opportunity>> actual = (Map<String, List<Opportunity>>) Collection.groupBy(opportunities, Opportunity.NextStep);
```




##### filter
Filters records and return only these accepted by Filter implementation.
SObject collections can be filtered by shorthand methods that use inbuilt Filter implementations (CollectionFilters.cls).

###### Methods:
```apex
Collection filter(SObjectField field, String operator, Object value)
Collection filter(Filter filter)
Collection filter(Map<Id, SObject> oldMap, UpdateFilter filter)

static List<SObject> filter(List<SObject> records, SObjectField field, String operator, Object value)
static List<Object> filter(List<Object> items, Filter filter)
static List<SObject> filter(List<SObject> records, Map<Id, SObject> oldRecords, UpdateFilter filter)
```    

###### Inbuilt Implementations (CollectionFilters)
```apex
ByFieldValue(SObjectField field, String operator, Object value)
ByFieldValues(SObjectField field, String operator, Set<Object> values)
RelatedTo(List<SObject> parents, SObjectField relationshipField)
ByDistance(SObjectField locationField, Location targetLocation, Double maxDistance, String unit)
FieldChanged(SObjectField field, Object fromValue, Object toValue)
```    

###### Interfaces
```apex
    /*
    * Filter determines whether collection item should be included into result collection of filter method.
    * */
    public interface Filter {
        Boolean accepts(Object item);
    }

    /*
    * Filter determines whether collection item should be included into result collection of filter method.
    * This kind of filter compares current record value with Trigger.old value.
    * */
    public interface UpdateFilter {
        Boolean accepts(SObject record, SObject oldRecord);
    }
```    

###### Examples
```apex
List<Opportunity> opportunities = Collection.filter(opportunities, oldMap, new OpportunityChangedNameFilter());
List<Opportunity> opportunities = (List<Opportunity>) new Collection(opportunities)
        .filter(oldMap, new OpportunityChangedNameFilter())
        .toList();
        
Collection.filter(opportunities, oldMap, new CollectionFilters.FieldChanged(Opportunity.Name, 'from', 'to'));
Collection.filter(opportunities, oldMap, new CollectionFilters.FieldChanged(Opportunity.Name, Collection.ANY_VALUE, Collection.ANY_VALUE));

Set<Datetime> relatedOppCreatedDates = (Set<Datetime>)
        new Collection(opportunities)
                .filter(new CollectionFilters.RelatedTo(accounts, Opportunity.AccountId))
                .getUniqueValues(Opportunity.CreatedDate);
                
                
Collection.filter(opportunities, new CollectionFilters.ByFieldValues(Opportunity.StageName, 'IN', acceptedStages));
Collection.filter(opportunities, new CollectionFilters.ByFieldValues(Opportunity.StageName, 'NOT IN', acceptedStages));
```    




##### find
Returns first collection element accepted by filter.

###### Methods:
```apex
SObject find(SObjectField field, String operator, Object value) 
Object find(Filter filter)
static SObject find(List<SObject> records, SObjectField field, String operator, Object value)
static Object find(List<Object> items, Filter filter)
```
 
###### Examples
```apex
Opportunity actual = (Opportunity) new Collection(opportunities).find(Opportunity.FiscalQuarter, '==', 3);
Opportunity actual = (Opportunity) new Collection(opportunities).find(new OpportunityNameContainsFilter('5'));

private class OpportunityNameContainsFilter implements Collection.Filter {
    private String expr;

    public OpportunityNameContainsFilter(String expr) {
        this.expr = expr;
    }

    public Boolean accepts(Object item) {
        return ((Opportunity) item).Name.contains(expr);
    }
}
```    




##### sort()
Sorts collection using given comparator. This is different from List.sort() which requires each collection element
to implement Comparable interface. 
Instead Comparator interface is used. 

###### Methods:
```apex
public Collection sort(SObjectField field, Boolean isAscending)
public Collection sort(Comparator comparator)

static List<SObject> sort(List<SObject> records, SObjectField field, Boolean isAscending)
static List<Object> sort(List<Object> items, Comparator comparator)
```

###### Interfaces
```apex
    /**
     * Compares 2 objects to determine their order.
     * The implementation of this method should return the following values:
     * 0 if thisItem and otherItem are equal
     * > 0 if thisItem is greater than otherItem
     * < 0 if thisItem is less than otherItem
     */
    public interface Comparator {
        Integer compare(Object thisItem, Object otherItem);
    }
```

###### Examples
```apex
        List<Opportunity> sortedOpportunities = Collection.sort(opportunities, Opportunity.CreatedDate, true);
        
        new Collection(opportunities)
                        .sort(Opportunity.FiscalQuarter, true)
                        .wrap(OpportunityWrapper.class);

        List<Opportunity> actual = (List<Opportunity>) new Collection(opportunities)
                .sort(new ReverseProbabilityComparator())
                .toList();

    private class ReverseProbabilityComparator implements Collection.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Opportunity thisOpp = (Opportunity) thisItem;
            Opportunity otherOpp = (Opportunity) otherItem;

            if (thisOpp.Probability < otherOpp.Probability) {
                return 1;

            } else if (thisOpp.Probability > otherOpp.Probability) {
                return -1;

            } else {
                return 0;
            }
        }
    }
```    





##### wrap()
Wraps collection items into wrapper classes.

###### Methods:
```apex
Collection wrap(Type wrapperType);
static List<Wrapper> wrap(List<Object> items, Type wrapperType);
```

###### Interfaces
```apex
    /**
     * Wrapper interface.
     * Concrete method implementing this interface should have a member variable for wrapped item.
     * setItem method should set that member variable.
     */
    public interface Wrapper {
        void setItem(Object item);
    }
```

###### Examples
```apex
    List<OpportunityWrapper2> wrappers = (List<OpportunityWrapper2>) Collection.wrap(opportunities, OpportunityWrapper2.class);
    
    List<OpportunityWrapper2> wrappers = (List<OpportunityWrapper2>)
        new Collection(opportunities)
                .filter(Opportunity.NextStep, '==', 'Analysis')
                .wrap(OpportunityWrapper2.class)
                .toList();


    public class OpportunityWrapper2 implements Collection.Wrapper {
        public Opportunity opportunity;

        public void setItem(Object item) {
            this.opportunity = (Opportunity) item;
        }

        public String getName() {
            return opportunity.Name;
        }
    }
```    



 

##### reduce()
Equivalent of Javascript's Array.reduce.
Executes reducer implementations on each member of collection resulting in single output value.
###### Methods:
```apex
    Object reduce(Reducer reducer, Object result)
    static Object reduce(List<Object> items, Reducer reducer, Object result)
```

###### Interfaces
```apex
    /**
     * @param aggregatedValues Collection which holds values reduced so far.
     * @param item currently processed item.
     * @return aggregatedValues
     */
    public interface Reducer {
        Object reduce(Object aggregatedValues, Object item, Integer index);
    }
```

###### Examples
```apex
    Decimal expected = 0;
    for (Opportunity opportunity : opportunities) {
        expected += opportunity.Amount;
    }

    Decimal actual = (Decimal) new Collection(opportunities).reduce(new ReducerToOppAmountTotal(), 0);

    System.assertEquals(expected, actual);
    
    
    private class ReducerToOppAmountTotal implements Collection.Reducer {
        public Object reduce(Object aggregatedValues, Object item, Integer index) {
            Decimal soFar = (Decimal) aggregatedValues;
            Opportunity opp = (Opportunity) item;

            return soFar + opp.Amount;
        }
    }
```    





##### forEach()
Executes action on each item of collection. This method can be useful in chaining.

###### Methods:
```apex
Collection forEach(Worker worker)
static void forEach(List<Object> items, Worker worker)
```

###### Interfaces
```apex
    /**
     * Worker performs action on each item in collection.
     */
    public interface Worker {
        void forEach(Object item, Integer index);
    }
```

###### Examples
```apex
    new Collection(opportunities)
            .filter(Opportunity.CreatedDate, '>=', Date.today().addDays(-3))
            .forEach(new AppendIndexToOpportunityNameWorker())
            .wrap(OpportunityWrapper2.class);
            
    private class AppendIndexToOpportunityNameWorker implements Collection.Worker {
        public void forEach(Object item, Integer index) {
            ((Opportunity) item).Name += index;
        }
    }
```    





##### fill()
Fills in the list with number of clones of provided prototype record.
By default, clone is deep and Id, timestamps and autonumbers are not preserved.

###### Methods:
```apex
Collection fill(Integer count, SObject prototype)
Collection fill(Integer count, SObject prototype, CloneOptions cloneOptions)

static List<SObject> fill(List<SObject> listToFill, Integer count, SObject prototype)
static List<SObject> fill(List<SObject> listToFill, Integer count, SObject prototype, CloneOptions opts)

```

###### Options
```apex
    public class CloneOptions {
        public Boolean
                preserveId,
                deepClone,
                preserveReadonlyTimestamps,
                preserveAutonumer;

        public CloneOptions(Boolean preserveId, Boolean deepClone, Boolean preserveReadonlyTimestamps, Boolean preserveAutonumer) {
            this.preserveId = preserveId;
            this.deepClone = deepClone;
            this.preserveReadonlyTimestamps = preserveReadonlyTimestamps;
            this.preserveAutonumer = preserveAutonumer;
        }
    }
```

###### Examples
```apex
        List<Account> accounts = (List<Account>)
                new Collection(new List<Account>())
                        .fill(10, new Account(Name = 'Test Account', Contact__r = contact))
                        .fill(10, new Account(Name = 'Other Account', Contact__r = contact),
                        new Collection.CloneOptions(false, false, false, false))
                        .toList();
```    





##### Utility methods
###### IsEmpty / isNotEmpty
NPE safe methods to check whether collection is empty or null.
```apex
    public Boolean isNotEmpty();
    public Boolean isEmpty();
    static Boolean isNotEmpty(List<Object> collection)
    static Boolean isEmpty(List<Object> collection)
```

###### Examples
```apex
    System.assertEquals(true, Collection.isEmpty(null));
    System.assertEquals(true, Collection.isEmpty(new List<String>()));
    System.assertEquals(true, new Collection(null).isEmpty());
    System.assertEquals(true, new Collection(new List<String>()).isEmpty());
```

###### public static Object cast(Object collection, Type targetType)
Forcefully transforms running type of the collection to specified type.

    Ex. Map<Object,Object> => Map<String,Account>
Casting is done through JSON serialization/deserialization, this process is CPU Time consuming.

This method is NPE-safe, when collection is null, then blank instance of target type is returned.
    
###### public static Type getListItemType(List&lt;Object&gt; o)
Return running type of Collections single item.
    
    Ex. for List<Account> => Account.class

###### static getType(Object o)
Returns running type of given object.


## Datatable
tbc
## XML Parser
tbc