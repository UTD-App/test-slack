<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Validation Language Lines
    |--------------------------------------------------------------------------
    |
    | The following language lines contain the default error messages used by
    | the validator class. Some of these rules have multiple versions such
    | as the size rules. Feel free to tweak each of these messages here.
    |
    */

    'accepted' => ':attribute को स्वीकार किया जाना चाहिए।',
    'accepted_if' => ':other को :value होने पर :attribute को स्वीकार किया जाना चाहिए।',
    'active_url' => ':attribute एक मान्य URL नहीं है।',
    'after' => ':attribute को :date के बाद की तारीख होनी चाहिए।',
    'after_or_equal' => ':attribute को :date के बाद या उसके समान तारीख होनी चाहिए।',
    'alpha' => ':attribute में केवल अक्षर होने चाहिए।',
    'alpha_dash' => ':attribute में केवल अक्षर, संख्या, डैश और अंडरस्कोर होने चाहिए।',
    'alpha_num' => ':attribute में केवल अक्षर और संख्याएं होनी चाहिए।',
    'array' => ':attribute एक एरे होना चाहिए।',
    'before' => ':attribute को :date के पहले की तारीख होनी चाहिए।',
    'before_or_equal' => ':attribute को :date के पहले या उसके समान तारीख होनी चाहिए।',
    'between' => [
        'numeric' => ':attribute :min और :max के बीच होना चाहिए।',
        'file' => ':attribute :min और :max किलोबाइट्स के बीच होना चाहिए।',
        'string' => ':attribute :min और :max अक्षरों के बीच होना चाहिए।',
        'array' => ':attribute में :min और :max आइटम होने चाहिए।',
    ],
    'boolean' => ':attribute फील्ड सही या गलत होना चाहिए।',
    'confirmed' => ':attribute पुष्टि मेल नहीं खाती।',
    'current_password' => 'पासवर्ड गलत है।',
    'date' => ':attribute एक मान्य तिथि नहीं है।',
    'date_equals' => ':attribute को :date के समान तिथि होना चाहिए।',
    'date_format' => ':attribute का प्रारूप :format के साथ मेल नहीं खाता है।',
    'declined' => ':attribute को अस्वीकार किया जाना चाहिए।',
    'declined_if' => ':other :value होने पर :attribute को अस्वीकार किया जाना चाहिए।',
    'different' => ':attribute और :other अलग होना चाहिए।',
    'digits' => ':attribute :digits अंक होना चाहिए।',
    'digits_between' => ':attribute :min और :max अंकों के बीच होना चाहिए।',
    'dimensions' => ':attribute अमान्य चित्र आयाम हैं।',
    'distinct' => ':attribute फील्ड में डुप्लिकेट मान है।',
    'email' => ':attribute एक मान्य ईमेल पता होना चाहिए।',
    'ends_with' => ':attribute निम्नलिखित में से किसी के साथ समाप्त होना चाहिए: :values।',
    'enum' => 'चयनित :attribute अमान्य है।',
    'exists' => 'चयनित :attribute अमान्य है।',
    'file' => ':attribute एक फ़ाइल होनी चाहिए।',
    'filled' => ':attribute फ़ील्ड में मान होना चाहिए।',
    'gt' => [
        'numeric' => ':attribute :value से अधिक होना चाहिए।',
        'file' => ':attribute :value किलोबाइट्स से अधिक होनी चाहिए।',
        'string' => ':attribute :value अक्षरों से अधिक होना चाहिए।',
        'array' => ':attribute में :value आइटम से अधिक होना चाहिए।',
    ],
    'gte' => [
        'numeric' => ':attribute :value से अधिक या उसके समान होना चाहिए।',
        'file' => ':attribute :value किलोबाइट्स से अधिक या उसके समान होना चाहिए।',
        'string' => ':attribute :value अक्षरों से अधिक या उसके समान होना चाहिए।',
        'array' => ':attribute में :value आइटम या उससे अधिक होना चाहिए।',
    ],
    'image' => ':attribute एक छवि होनी चाहिए।',
    'in' => 'चयनित :attribute अमान्य है।',
    'in_array' => ':attribute फ़ील्ड :other में मौजूद नहीं है।',
    'integer' => ':attribute एक पूर्णांक होना चाहिए।',
    'ip' => ':attribute एक मान्य IP पता होना चाहिए।',
    'ipv4' => ':attribute एक मान्य IPv4 पता होना चाहिए।',
    'ipv6' => ':attribute एक मान्य IPv6 पता होना चाहिए।',
    'json' => ':attribute एक मान्य JSON स्ट्रिंग होनी चाहिए।',
    'lt' => [
        'numeric' => ':attribute :value से कम होना चाहिए।',
        'file' => ':attribute :value किलोबाइट्स से कम होना चाहिए।',
        'string' => ':attribute :value अक्षरों से कम होना चाहिए।',
        'array' => ':attribute में :value आइटम से कम होना चाहिए।',
    ],
    'lte' => [
        'numeric' => ':attribute :value से कम या उसके समान होना चाहिए।',
        'file' => ':attribute :value किलोबाइट्स से कम या उसके समान होना चाहिए।',
        'string' => ':attribute :value अक्षरों से कम या उसके समान होना चाहिए।',
        'array' => ':attribute में :value आइटम से अधिक नहीं होना चाहिए।',
    ],
    'mac_address' => ':attribute एक मान्य MAC पता होना चाहिए।',
    'max' => [
        'numeric' => ':attribute :max से अधिक नहीं होना चाहिए।',
        'file' => ':attribute :max किलोबाइट्स से अधिक नहीं होना चाहिए।',
        'string' => ':attribute :max अक्षरों से अधिक नहीं होना चाहिए।',
        'array' => ':attribute में :max आइटम से अधिक नहीं होना चाहिए।',
    ],
    'mimes' => ':attribute :values प्रकार की फ़ाइल होनी चाहिए।',
    'mimetypes' => ':attribute :values प्रकार की फ़ाइल होनी चाहिए।',
    'min' => [
        'numeric' => ':attribute कम से कम :min होना चाहिए।',
        'file' => ':attribute कम से कम :min किलोबाइट्स होनी चाहिए।',
        'string' => ':attribute कम से कम :min अक्षर होने चाहिए।',
        'array' => ':attribute में कम से कम :min आइटम होने चाहिए।',
    ],
    'multiple_of' => ':attribute :value की गुणा होना चाहिए।',
    'not_in' => 'चयनित :attribute अमान्य है।',
    'not_regex' => ':attribute प्रारूप अमान्य है।',
    'numeric' => ':attribute एक संख्या होनी चाहिए।',
    'password' => 'पासवर्ड गलत है।',
    'present' => ':attribute फ़ील्ड मौजूद होना चाहिए।',
    'prohibited' => ':attribute फ़ील्ड मना है।',
    'prohibited_if' => ':other :value होने पर :attribute फ़ील्ड मना है।',
    'prohibited_unless' => ':other :values में न होने पर :attribute फ़ील्ड मना है।',
    'prohibits' => ':attribute फ़ील्ड :other को मौजूद नहीं होने देता है।',
    'regex' => ':attribute प्रारूप अमान्य है।',
    'required' => ':attribute फ़ील्ड आवश्यक है।',
    'required_array_keys' => ':attribute फ़ील्ड में :values के लिए प्रविष्टियाँ होनी चाहिए।',
    'required_if' => ':attribute फ़ील्ड :other :value होने पर आवश्यक है।',
    'required_unless' => ':attribute फ़ील्ड :other :values में न होने पर आवश्यक है।',
    'required_with' => ':values मौजूद होने पर :attribute फ़ील्ड आवश्यक है।',
    'required_with_all' => ':values मौजूद होने पर :attribute फ़ील्ड आवश्यक है।',
    'required_without' => ':values मौजूद न होने पर :attribute फ़ील्ड आवश्यक है।',
    'required_without_all' => ':values में से कोई भी मौजूद न होने पर :attribute फ़ील्ड आवश्यक है।',
    'same' => ':attribute और :other मेल खाने चाहिए।',
    'size' => [
        'numeric' => ':attribute :size होना चाहिए।',
        'file' => ':attribute :size किलोबाइट्स होने चाहिए।',
        'string' => ':attribute :size अक्षर होने चाहिए।',
        'array' => ':attribute में :size आइटम होने चाहिए।',
        ],
        'starts_with' => ':attribute निम्नलिखित में से किसी एक के साथ शुरू होना चाहिए: :values।',
        'string' => ':attribute एक स्ट्रिंग होनी चाहिए।',
        'timezone' => ':attribute एक मान्य समय क्षेत्र होना चाहिए।',
        'unique' => ':attribute पहले से ही लिया जा चुका है।',
        'uploaded' => ':attribute अपलोड करने में विफल हुआ।',
        'url' => ':attribute एक मान्य URL होना चाहिए।',
        'uuid' => ':attribute एक मान्य UUID होना चाहिए।',

    /*
    |--------------------------------------------------------------------------
    | Custom Validation Language Lines
    |--------------------------------------------------------------------------
    |
    | Here you may specify custom validation messages for attributes using the
    | convention "attribute.rule" to name the lines. This makes it quick to
    | specify a specific custom language line for a given attribute rule.
    |
    */

    'custom' => [
        'username' => [
            'unique' => 'यह उपयोगकर्ता नाम उपलब्ध नहीं है।',
        ],
        'attribute-name' => [
            'rule-name' => 'custom-message',
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Custom Validation Attributes
    |--------------------------------------------------------------------------
    |
    | The following language lines are used to swap our attribute placeholder
    | with something more reader friendly such as "E-Mail Address" instead
    | of "email". This simply helps us make our message more expressive.
    |
    */

    'attributes' => [],

];
