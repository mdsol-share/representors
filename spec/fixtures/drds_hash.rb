module ComplexRepresentor
DRDS_HASH = {
  href: 'www.example.com/drds',
  id: 'DRDs',
  protocol: 'http',
  doc: 'Describes the semantics, states and state transitions associated with DRDs.', 
  links: {
    profile: 'http://www.example.com/drds/show/DRDs',
    help: 'http://alps.io/schema.org/DRDs'
  },
  attributes: { 
    "total_count" => { 
      doc: 'The total count of DRDs.', 
      type: 'semantic', 
      profile: 'http://alps.io/schema.org/Integer', 
      sample: 1, 
      value: 2, 
    },
  },
  transitions: [
    {
      rel: 'self', 
      href: 'http://example.com/drds', 
      method: 'GET', 
    },
    {
      rel: 'list',
      doc: 'Returns a list of DRDs.', 
      profile: 'http://alps.io/schema.org/DRDs', 
      href: 'http://example.com/drds/list',
    },
    {
      rel: 'search',
      doc: 'Returns a list of DRDs that satisfy the search term.',
      href: 'http://example.com/drds/search',
      rt: 'drds',
      descriptors: {
        search_term: {
          doc: 'The terms to search.',
          profile: 'http://alps.io/schema.org/Text',
          sample: 'searchterm',
          multiple: true,
          scope: 'href',
        },
        name: { 
          doc: 'The name of the DRD.',
          profile: 'http://alps.io/schema.org/Text',
          sample: 'drdname',
          value: 'drdname',
          scope: 'href',
          field_type: 'text', 
        },
      },
    },        
    {
      rel: 'create',
      doc: 'Creates a DRD.',
      rt: 'drd',
      links: {
        profile: 'http://alps.io/schema.org/DRDs#update',
        help: 'http://help.example.com/Forms/update',
      },
      href: 'www.example.com/drds/create',
      method: 'POST',
      descriptors: { 
        name: { 
          doc: 'The name of the DRD.',
          profile: 'http://alps.io/schema.org/Text',
          sample: 'drdname',
          field_type: 'text', #
          validators: [
            'required',
            {maxlength: 50},
          ],
        },
        leviathan: {
          doc: 'The associated Leviathan resource.',
          profile: 'http://alps.io/schema.org/Thing/Leviathan',
          sample: 'http://alps.io/schema.org/Thing/Leviathan',
          value: 'http://alps.io/schema.org/Thing/Leviathan',
          type: 'object', #TODO Embedded Objects
          descriptors: {
            leviathan_uuid: {
              doc: 'The UUID of the creator Leviathan.',
              profile: 'http://alps.io/schema.org/Text',
              sample: '007d8e12-babd-4f2c-b01e-8b5e2f749e1b',
              type: 'text',
              field_type: 'text', 
            },
            leviathan_health_points: {
              doc: 'The health points of Leviathan.',
              profile: 'http://alps.io/schema.org/Integer',
              type: 'integer',
              field_type: 'number',
              validators: [
                'required',
                {min: 0},
                {max: 100},
              ],
              sample: 42,
            },
            leviathan_email: {
              doc: 'The Leviathan respond to email.',
              profile: 'http://alps.io/schema.org/Text',
              sample: 'joe@grumpycat.org',
              type: 'text',
              field_type: 'email',
              validators: [
                'required',
                {pattern: "^.+@.+$"}
              ]
            },
          },
        },
      },
    },
  ],
  #To put embedded items in the hash please see: single_drd.rb
}
end
    