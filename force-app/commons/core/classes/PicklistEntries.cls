/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

/**
 * @description
 *
 *
 * @author Piotr Kożuchowski
 */
public with sharing class PicklistEntries {
    private transient List<PicklistEntry> entries;
    private String defaultValue;
    private List<String> values;
    private List<String> labels;
    private transient Map<String, String> valueToLabel;
    private Boolean isRestricted;
    private Boolean isDependant;

    /**
     * Factory method which creates instance of PicklistEntries for given SObjectField
     */
    public static PicklistEntries of(SObjectField field) {
        return new PicklistEntries(field);
    }

    private PicklistEntries(SObjectField field) {
        DescribeFieldResult describe = field.getDescribe();
        this.entries = new List<PicklistEntry>();
        this.values = new List<String>();
        this.labels = new List<String>();
        this.valueToLabel = new Map<String, String>();
        this.isRestricted = describe.isRestrictedPicklist();
        this.isDependant = describe.isDependentPicklist();

        for (PicklistEntry entry : describe.getPicklistValues()) {
            if (entry.isActive()) {
                this.entries.add(entry);
                this.values.add(entry.getValue());
                this.labels.add(entry.getLabel());
                this.valueToLabel.put(entry.getValue().toLowerCase(), entry.getLabel());

                if (entry.isDefaultValue()) {
                    this.defaultValue = entry.getValue();
                }
            }
        }
    }


    /**
     * @return True, if picklist is restricted.
     */
    public Boolean isRestrictedPicklist() {
        return this.isRestricted;
    }

    /**
     * @return True, if picklist is dependant picklist
     */
    public Boolean isDependentPicklist() {
        return this.isDependant;
    }

    /**
     * @return True, if picklist contains given value (case insensitive).
     */
    public Boolean containsValue(String value) {
        return valueToLabel.keySet().contains(value.toLowerCase());
    }

    /**
     * @return Picklist's default value or null.
     */
    public String getDefaultValue() {
        return defaultValue;
    }

    /**
     * @return API Names of all active picklist values.
     */
    public List<String> getValues() {
        return values;
    }

    /**
     * @return Labels of all active picklist values.
     */
    public List<String> getLabels() {
        return labels;
    }

    /**
     * @return Label corresponding to the given picklist value.
     */
    public String getLabel(String value) {
        return valueToLabel.get(value.toLowerCase());
    }

    /**
     * @return AuraEnabled collection of active picklist entries
     */
    public List<Entry> getEntries() {
        List<Entry> selectOptions = new List<Entry>();

        for (PicklistEntry picklistEntry : entries) {
            selectOptions.add(new Entry(picklistEntry));
        }

        return selectOptions;
    }

    /**
     * @return Visualforce SelectOptions of active picklist entries.
     */
    public List<SelectOption> getSelectOptions() {
        List<SelectOption> selectOptions = new List<SelectOption>();

        for (PicklistEntry picklistEntry : entries) {
            selectOptions.add(new SelectOption(picklistEntry.getValue(), picklistEntry.getLabel()));
        }

        return selectOptions;
    }


    /**
     * AuraEnabled wrapper for Picklist Entry
     */
    public class Entry {
        @AuraEnabled public String label { get; private set; }
        @AuraEnabled public String value { get; private set; }
        @AuraEnabled public Boolean isDefault { get; private set; }

        private Entry(PicklistEntry picklistEntry) {
            this.label = picklistEntry.getLabel();
            this.value = picklistEntry.getValue();
            this.isDefault = picklistEntry.isDefaultValue();
        }
    }
}