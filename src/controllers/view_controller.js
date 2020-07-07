import { Controller } from "stimulus";
import axios from 'axios';

// TODO: Write a manual if this stays in the code base.
export default class extends Controller {
  static targets = [ "output", "hidden" ]

  connect() {
    // Default mode
    this.mode = "replace";
    this.name = "unnamed";
    this.url = "/";

    if(this.data.has("url")){
        this.url = this.data.get("url");
     }
    if(this.data.has("mode")){
       this.mode = this.data.get("mode");
    }
    if(this.data.has("name")){
      this.name = this.data.get("name");
    }
  }

  visit(target){
      console.log("Visit:" + this.url);
      let controller = this;
      axios.get(this.url)
      .then(function (response) {
        // handle success
        console.log(response);
        controller.success(response);

      })
      .catch(function (error) {
        // handle error
        console.log(error);
      })
      .then(function () {
        // always executed
      });
  }

  success(response){
    let match = true;

    if(this.name !== "unnamed"){
      match = response.srcElement.dataset.name == this.name;
      console.log("Name NOT MATCHED " + this.name);
    }
    // Check who is the author of the event...

    if(match){
       // response.stopPropagation();
      this.hiddenTargets.forEach(element => {
	    element.classList.remove("d-none");
      });

      if(this.mode === "add"){
	this.outputTarget.innerHTML +=  response.data;
      }

      if(this.mode === "remove"){
	    this.outputTarget.innerHTML = "";
      }

      if(this.mode === "remove-self"){
	   this.element.remove();
      }

      if(this.mode === "replace"){
	    this.outputTarget.innerHTML = response.data;
      }

      if(this.mode === "replace-self"){
	    this.element.innerHTML =  response.data;
      }
    }
  }

  error(response){
    console.log("Error");
    console.log(response);
    this.outputTarget.innerHTML = response.detail[0];
  }
}
