using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FoxServer {
    public class URI {
        public string apiPath { get; set; } // ej: api/v1/
        public string url { get; set; }     // api/v1/customers
        public string path { get; set; }    // ej: customers/
        public string urlFile { get; set; } // ej: customer.html
        public string urlParam { get; set; }// ej: 15, fdsfjkj342342
    }
}
